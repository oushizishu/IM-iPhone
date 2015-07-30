//
//  BJAudioBufferRecorder.m
//  BJEducation
//
//  Created by Randy on 14/12/2.
//  Copyright (c) 2014年 com.bjhl. All rights reserved.
//

#import "BJAudioBufferRecorder.h"
#import "RecordAudio.h"
#import <AVFoundation/AVMediaFormat.h>
#import "lame.h"
#import "UIAlertView+Block.h"
#import "UIDevice+IdentifierAddition.h"
#import "BJCommonDefines.h"
#import "JLMicrophonePermission.h"
@interface BJAudioBufferRecorder ()
{
    FILE *mp3File;
    lame_t lame;
}
@property (strong, nonatomic)NSString *recordedTmpFile;
@property (assign, nonatomic)BOOL isCancel;
@property (assign, atomic)NSInteger recordTime;
@property (assign, atomic)BOOL isActive;
@property (strong, nonatomic)dispatch_queue_t lameQueue;
@end
@implementation BJAudioBufferRecorder

static void AQInputCallback (void                   * inUserData,
                             AudioQueueRef          inAudioQueue,
                             AudioQueueBufferRef    inBuffer,
                             const AudioTimeStamp   * inStartTime,
                             UInt32          inNumPackets,
                             const AudioStreamPacketDescription * inPacketDesc)
{
    __weak BJAudioBufferRecorder * engine = (__bridge BJAudioBufferRecorder *) inUserData;
    if (engine.aqc.run)
    {
        engine.recordTime = inStartTime->mSampleTime / engine.sampleRate;
        if (inNumPackets > 0)
        {
            [engine processAudioBuffer:inBuffer withQueue:inAudioQueue];
        }
        AudioQueueEnqueueBuffer(engine.aqc.queue, inBuffer, 0, NULL);
    }
}

- (id)init
{
    return [self initWithSampleRate:kSamplingRate];
}

- (id) initWithSampleRate:(float)sr
{
    self = [super init];
    
    if (self)
    {
        _aqc.mDataFormat.mSampleRate = sr;
        _aqc.mDataFormat.mFormatID = kAudioFormatLinearPCM;
        _aqc.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _aqc.mDataFormat.mFramesPerPacket = 1;
        _aqc.mDataFormat.mChannelsPerFrame = kNumberChannels;
        _aqc.mDataFormat.mBitsPerChannel = kBitsPerChannels;
        _aqc.mDataFormat.mBytesPerPacket = kBytesPerFrame;
        _aqc.mDataFormat.mBytesPerFrame = kBytesPerFrame;
        _aqc.frameSize = kFrameSize;
        
        lame = lame_init();
        lame_set_in_samplerate(lame, _aqc.mDataFormat.mSampleRate);
        lame_set_num_channels(lame, kNumberChannels);
        lame_set_mode(lame, 1);
        lame_set_brate(lame, 128);// 压缩的比特率为128K
        
        //低设备
        if ([UIDevice isLowDevice]) {
            lame_set_quality(lame, 5);
        }
        else
            lame_set_quality(lame, 2);
        lame_init_params(lame);
        _aqc.run = 1;
        _lameQueue = dispatch_queue_create("com.bjhl.audioBufferRecorder.lame", DISPATCH_QUEUE_SERIAL);
        _isLameFinish = YES;
    }
    
    return self;
}

- (void) dealloc
{
    [self cancelRecord];
    lame_t lameTmp = lame;
    dispatch_async(self.lameQueue, ^{
        if (lameTmp) {
            lame_close(lameTmp);
        }
    });
}

- (Float64)sampleRate
{
    return _aqc.mDataFormat.mSampleRate;
}

- (void)openMp3File
{
    mp3File = fopen([self.recordedTmpFile cStringUsingEncoding:1], "wb");
}

- (BOOL)isRecording
{
    return self.isActive;
}

- (void)_startRecord:(AudioBufferRecoderCallback)callback
{
    _aqc.run = 1;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: nil];
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    [audioSession setActive:YES error: nil];
    self.isActive = YES;
    self.recordedTmpFile = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mp3"]];
    __weak BJAudioBufferRecorder *weakSelf = self;
    
    dispatch_async(weakSelf.lameQueue, ^{
        weakSelf.isLameFinish = NO;
        [weakSelf openMp3File];
    });
    OSStatus status = AudioQueueNewInput(&_aqc.mDataFormat, AQInputCallback, (__bridge void *)(weakSelf), NULL, kCFRunLoopCommonModes, 0, &_aqc.queue);
    if (status != errSecSuccess) {
    }
    for (int i=0;i<kNumberBuffers;i++)
    {
        status = AudioQueueAllocateBuffer(_aqc.queue, (UInt32)_aqc.frameSize, &_aqc.mBuffers[i]);
        status = AudioQueueEnqueueBuffer(_aqc.queue, _aqc.mBuffers[i], 0, NULL);
    }
    status = AudioQueueStart(_aqc.queue, NULL);
    if (status != errSecSuccess) {
        self.finishCallback([NSString stringWithFormat:@"录音失败 错误code：%d",(int)status],0,NO,NO);
        callback(NO);
    }
    else
    {
        self.recordTime = 0;
        callback(true);
    }
}

- (void)startRecord:(AudioBufferRecoderCallback)callback
{
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")){
        [self _startRecord:callback];
        return;
    }
    
    [[JLMicrophonePermission sharedInstance] authorize:^(bool granted, NSError *error) {
        if (!granted)
        {
            if (error.code == JLPermissionSystemPeriousAskedDenied) {
                [[JLMicrophonePermission sharedInstance] displayReenableAlert];
            }
            if (callback) {
                callback(granted);
            }
        }
        else
        {
            [self _startRecord:callback];
        }
    }];
}

- (void)timerAction
{
    if (self.recordTime >= self.duration && self.duration>0) {
        [self stopRecord];
    }
    else if(self.remainingCallback){
        self.remainingCallback(self.recordTime);
    }
}

- (void)stopRecord
{
    [self _stopRecord];
    if (self.finishCallback) {
        self.finishCallback(self.recordedTmpFile,self.recordTime,YES,NO);
    }
    [self _stopLame];
}

- (void)cancelRecord
{
    [self _stopRecord];
}

- (void)_stopLame
{
    __weak BJAudioBufferRecorder *weakSelf = self;
    FILE *mp3FileTmp = mp3File;
    dispatch_async(weakSelf.lameQueue, ^{
        if (weakSelf && mp3FileTmp) {
            fclose(mp3FileTmp);
        }
        weakSelf.isLameFinish = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.finishCallback) {
                weakSelf.finishCallback(weakSelf.recordedTmpFile,self.recordTime,YES,YES);
            }
        });
    });
    mp3File = NULL;
}

- (void)_stopRecord
{
    _aqc.run = 0;
    
    AudioQueueStop(_aqc.queue, true);
    AudioQueueDispose(_aqc.queue, true);
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    if (self.isActive) {
        [audioSession setActive:NO error: nil];
        self.isActive = NO;
    }
}

- (void)enableLevelMetering:(BOOL)enable
{
    int32_t on = enable;
    OSStatus rc = AudioQueueSetProperty(_aqc.queue, kAudioQueueProperty_EnableLevelMetering, &on, sizeof(on));
    //    DDLogDebug(@"kAudioQueueProperty_EnableLevelMetering ret:%d", (int)rc);
}

- (double)audioMeter
{
    UInt32 dataSize = sizeof(AudioQueueLevelMeterState) * _aqc.mDataFormat.mChannelsPerFrame;
    AudioQueueLevelMeterState *levels = (AudioQueueLevelMeterState*)malloc(dataSize);
    
    OSStatus rc = AudioQueueGetProperty(_aqc.queue, kAudioQueueProperty_CurrentLevelMeter, levels, &dataSize);
    if (rc) {
        free(levels);    // This works since in this sole box one channel always has an mAveragePower of 0.   relapse channelAvg;
        NSLog(@"NoiseLeveMeter>>takeSample - AudioQueueGetProperty(CurrentLevelMeter) returned %d", rc);
        return 0;
    }
    
    double channelAvg = 0;
    for (int i = 0; i < _aqc.mDataFormat.mChannelsPerFrame; i++) {
        channelAvg += levels[i].mPeakPower;
    }
    free(levels);    // This works since in this sole box one channel always has an mAveragePower of 0.   relapse channelAvg;
    
    return channelAvg / _aqc.mDataFormat.mChannelsPerFrame;
}

- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue
{
    __weak BJAudioBufferRecorder *theModel = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [theModel timerAction];
    });
    long dataSize = buffer->mAudioDataByteSize;
    long size = buffer->mAudioDataByteSize / _aqc.mDataFormat.mBytesPerFrame;
    t_sample * data = (t_sample *) buffer->mAudioData;
    t_sample * copyData = (t_sample *)malloc(dataSize);
    memcpy(copyData, data, dataSize);
    lame_t lameTmp = lame;
    FILE *mp3FileTmp = mp3File;
    dispatch_async(theModel.lameQueue, ^{
        @try {
            if (theModel && mp3FileTmp) {
                int write;
                unsigned char mp3_buffer[dataSize];
                write = lame_encode_buffer(lameTmp, copyData,NULL, (int)size, mp3_buffer, 0);
                fwrite(mp3_buffer, write, 1, mp3FileTmp);
            }
        }
        @catch (NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //                DDLogError(@"%@",[exception description]);
                
                [theModel _stopRecord];
                [theModel _stopLame];
                theModel.finishCallback([NSString stringWithFormat:@"转码失败 原因：%@",[exception description]],0,NO,NO);
            });
        }
        @finally {
            
        }
        free(copyData);
    });
    
    
    //NSLog(@"processAudioData :%ld", buffer->mAudioDataByteSize);
    
    //处理data
}


@end

