//
//  BJAudioBufferRecorder.h
//  BJEducation
//
//  Created by Randy on 14/12/2.
//  Copyright (c) 2014年 com.bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "RecordAudio.h"
// use Audio Queue

// Audio Settings
#define kNumberBuffers      3

#define t_sample             SInt16

#define kSamplingRate       44100
#define kNumberChannels     1
#define kBitsPerChannels    (sizeof(t_sample) * 8)
#define kBytesPerFrame      (kNumberChannels * sizeof(t_sample))
//#define kFrameSize          (kSamplingRate * sizeof(t_sample))
#define kFrameSize          1000

typedef void (^AudioBufferRecoderCallback)(BOOL isStart);

typedef struct AQCallbackStruct
{
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef               queue;
    AudioQueueBufferRef         mBuffers[kNumberBuffers];
    AudioFileID                 outputFile;
    
    unsigned long               frameSize;
    int                         run;
} AQCallbackStruct;
@interface BJAudioBufferRecorder : RecordAudio
{
    AQCallbackStruct _aqc;
}

@property (assign, atomic)BOOL isLameFinish;
@property (readonly, nonatomic, assign)Float64 sampleRate;

- (id)initWithSampleRate:(float)sr;
- (void)startRecord:(AudioBufferRecoderCallback)callback;
- (void)enableLevelMetering:(BOOL)enable;
- (double)audioMeter;
- (float) peakPower;

@property (nonatomic, assign) AQCallbackStruct aqc;

@end
