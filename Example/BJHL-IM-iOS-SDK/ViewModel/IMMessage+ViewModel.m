//
//  IMMessage+ViewModel.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "IMMessage+ViewModel.h"
#import <IMEnvironment.h>
#import <IMTxtMessageBody.h>
#import <IMImgMessageBody.h>
#import <IMAudioMessageBody.h>
#import <IMEmojiMessageBody.h>

#import "BJChatAudioPlayerHelper.h"
@implementation IMMessage (ViewModel)

- (BOOL)isMySend;    //是否是自己发送的
{
    if (self.sender == [IMEnvironment shareInstance].owner.userId &&
        self.senderRole == [IMEnvironment shareInstance].owner.userRole) {
        return YES;
    }
    return NO;
}

- (BOOL)isRead;      //是否已读
{
    return self.read;
}

- (IMMessageStatus)deliveryStatus;
{
    return self.status;
}

- (NSURL *)headImageURL;
{
    return nil;
}

- (NSString *)nickName;
{
    return nil;
}

- (NSString *)content;//text
{
    if ([self.messageBody isKindOfClass:[IMTxtMessageBody class]]) {
        IMTxtMessageBody *body = (IMTxtMessageBody *)self.messageBody;
        return body.content;
    }
    NSAssert(0, @"类型不是IMTxtMessageBody，请检查");
    return nil;
}

#pragma mark - image
- (CGSize)size
{
    @TODO("计算size");
    return CGSizeZero;
}

- (NSURL *)imageURL
{
    @TODO("返回图片路径");
    return nil;
}

#pragma mark - EMOJI
- (NSString *)emojiName;
{
    @TODO("返回emoji的名字");
    return nil;
}

#pragma mark - Audio
//audio
- (NSURL *)audioURL;
{
    @TODO("返回音频地址");
    return nil;
}

- (NSInteger)time;
{
    @TODO("返回正确的时间");
    return 20;
}
- (BOOL)isPlayed;
{
    @TODO("返回正确的状态");
    return NO;
}

- (BOOL)isPlaying
{
    return [[BJChatAudioPlayerHelper sharedInstance] isPlayerWithMessage:self];
}

@end
