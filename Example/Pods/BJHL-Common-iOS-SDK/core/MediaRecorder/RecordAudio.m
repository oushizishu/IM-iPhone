//
//  RecordAudio.m
//
//  Created by Randy on 14-11-27.
//  Copyright (c) 2014年 com.bjhl. All rights reserved.
//

#import "RecordAudio.h"
#import <AVFoundation/AVFoundation.h>
#import "BJTimer.h"
#import "lame.h"
@interface RecordAudio ()
@property (strong, nonatomic)AVAudioRecorder *recorder;
@property (strong, nonatomic)NSString *recordedTmpFile;
@property (assign, nonatomic)BOOL isCancel;
@property (strong, nonatomic)BJTimer *timer;
@end

@implementation RecordAudio

- (void)dealloc
{

    [self cancelRecord];
    [self.recorder deleteRecording];
    [self.recorder setDelegate:nil];
}

-(id)init
{
    self = [super init];
    if (self) {

        self.duration = 180;
    }
    return self;
}

- (BOOL)isRecording
{
    if (self.recorder){
        return self.recorder.isRecording;
    }
    return false;
}


- (void) stopRecord {

    if (self.recorder.isRecording) {
        [self.recorder stop];
    }
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error: nil];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

-(void) startRecord {

    self.isCancel = NO;
    NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                       [NSNumber numberWithFloat:44100.00], AVSampleRateKey,
                                       [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                       [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                      [NSNumber numberWithInt:AVAudioQualityMin],
                                   AVEncoderAudioQualityKey,
                                       nil];
    
    self.recordedTmpFile = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]];
    NSLog(@"Using File called: %@",self.recordedTmpFile);
    NSError *error;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: nil];
    [audioSession setActive:YES error: nil];
    self.recorder = [[ AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.recordedTmpFile] settings:recordSetting error:&error];
    if (!error) {

        [self.recorder setDelegate:self];
        self.recorder.meteringEnabled=YES;
        if (self.duration>0) {
            [self.recorder recordForDuration:self.duration];
        }
        
        if (self.remainingCallback) {
            self.timer = [BJTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(remainingTimerAction) forMode:NSRunLoopCommonModes];
        }
    }
    else
    {
        self.finishCallback(error.localizedFailureReason, 0, NO, NO);
    }
}

-(void)cancelRecord
{
    self.isCancel = YES;
    [self stopRecord];
}

- (void)remainingTimerAction
{
    if (self.remainingCallback) {
        CGFloat time = self.recorder.currentTime;
        self.remainingCallback(time);
    }
}


- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (!self.isCancel) {
        NSString *messageStr = nil;
        if (flag)
        {
            messageStr = self.recordedTmpFile;
        }
        else
        {
            messageStr = @"录制音频失败";
        }
        if (self.finishCallback) {
            self.finishCallback(messageStr, self.recorder.currentTime, flag,YES);
        }
    }
    [self.timer invalidate];
    self.timer = nil;
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    [self.timer invalidate];
    self.timer = nil;
    if (!self.isCancel && self.finishCallback)
        self.finishCallback(error.localizedFailureReason, 0, NO,NO);
}

@end
