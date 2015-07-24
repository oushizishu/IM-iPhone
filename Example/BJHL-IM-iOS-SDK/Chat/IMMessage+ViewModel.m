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


@end