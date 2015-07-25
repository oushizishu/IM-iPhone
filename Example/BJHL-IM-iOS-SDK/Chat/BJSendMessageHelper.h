//
//  BJSendMessageHelper.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Conversation.h>

#import <IMMessage.h>
#import <BJIMManager.h>

#import "BJChatInfo.h"
@interface BJSendMessageHelper : NSObject
+ (void)sendTextMessage:(NSString *)text chatInfo:(BJChatInfo *)chatInfo;

@end
