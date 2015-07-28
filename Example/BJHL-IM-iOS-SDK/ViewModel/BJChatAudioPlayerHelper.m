//
//  BJAudioPlayerWithCache.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatAudioPlayerHelper.h"
#import <BJAudioPlayer.h>
#import "IMMessage+ViewModel.h"

@interface BJChatAudioPlayerHelper ()
@property (strong, nonatomic) BJAudioPlayer *player;
@property (strong, nonatomic) IMMessage *message;
@property (copy, nonatomic) ChatAudioPlayerFinishCallback callback;
@end

@implementation BJChatAudioPlayerHelper

+ (instancetype)sharedInstance
{
    static BJChatAudioPlayerHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)startPlayerWithMessage:(IMMessage *)message callback:(ChatAudioPlayerFinishCallback)callback;
{
    @TODO("播放并缓存数据");
    self.callback = callback;
    self.message = message;
    [self.player startPlayWithUrl:message.audioURL];
}

- (void)stopPlayerWithMessage:(IMMessage *)message;
{
    if ([self isPlayerWithMessage:message]) {
        [self.player stopPlay];
        self.message = nil;
    }
}

- (BOOL)isPlayerWithMessage:(IMMessage *)message;
{
    return [self.player isPlayerWithUrl:message.audioURL];
}

#pragma mark - set get
- (BJAudioPlayer *)player
{
    if (_player == nil) {
        _player = [[BJAudioPlayer alloc] init];
        __weak typeof(self) weakSelf = self;
        _player.callback = ^(NSString *message, BOOL isFinish){
            if (isFinish && weakSelf.callback) {
                NSError *error = nil;
                if (message.length>0) {
                    error = [NSError errorWithDomain:@"BJChat" code:100 userInfo:@{NSLocalizedFailureReasonErrorKey:message}];
                }
                weakSelf.callback(error);
            }
        };
    }
    return _player;
}

@end
