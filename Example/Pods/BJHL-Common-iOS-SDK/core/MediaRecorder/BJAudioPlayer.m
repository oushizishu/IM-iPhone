//
//  BJAudioPlayer.m
//  BJEducation
//
//  Created by Randy on 14/11/29.
//  Copyright (c) 2014年 com.bjhl. All rights reserved.
//

#import "BJAudioPlayer.h"
#import "BJTimer.h"

@interface BJAudioPlayer ()<AVAudioPlayerDelegate>
@property (strong, nonatomic)AVAudioPlayer * avPlayer;
@property (nonatomic) BOOL playStatu; // 0 : 停止 ， 1: 正在播放
@property (strong, nonatomic)BJTimer *timer;
@property (assign, nonatomic)BOOL isActive;

@property (nonatomic, strong) NSString * originAudioCategory;
@end

@implementation BJAudioPlayer
- (void)dealloc
{
    [self stopPlay];
}

-(id)init{
    self=[super init];
    if (self) {
        
    }
    return self;
}

- (void)timerAction
{
    if (self.proressCallback) {
        self.proressCallback(self.avPlayer.currentTime,self.avPlayer.duration);
    }
}

-(BOOL) startPlayWithUrl:(NSURL *)url{
    if (!url) {
        return NO;
    }
    self.originAudioCategory = [[AVAudioSession sharedInstance] category];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:NULL];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    self.isActive = YES;
    
    if (self.avPlayer!=nil) {
        [self.avPlayer stop];
        // return;
    }
    _playStatu= YES;
    NSError *error;
    self.avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error) {
        [self stopPlay];
        return NO;
    }
    self.avPlayer.delegate = self;
    [self.avPlayer prepareToPlay];
    [self.avPlayer setVolume:1.0];
    self.timer = [BJTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction) forMode:NSDefaultRunLoopMode];
    
    [self.avPlayer play];
    return YES;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (self.callback) {
        self.callback(nil,YES);
    }
    [self stopPlay];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    if (self.callback) {
        self.callback(error.localizedFailureReason, NO);
    }
    [self stopPlay];
}

-(void) stopPlay {
    _playStatu = NO;
    if (self.avPlayer!=nil) {
        [self.avPlayer stop];
    }
    if (self.isActive) {
        [[AVAudioSession sharedInstance] setActive:NO error: nil];
        self.isActive = NO;
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:self.originAudioCategory error: nil];
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    }
    
    [self.timer invalidate];
    self.timer = nil;
}
@end
