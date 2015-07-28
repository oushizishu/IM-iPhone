//
//  BJAudioPlayerWithCache.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IMMessage.h>
typedef void (^ChatAudioPlayerFinishCallback)(NSError *error);

@interface BJChatAudioPlayerHelper : NSObject
+ (instancetype)sharedInstance;
- (void)startPlayerWithMessage:(IMMessage *)message callback:(ChatAudioPlayerFinishCallback)callback;
- (void)stopPlayerWithMessage:(IMMessage *)message;
- (BOOL)isPlayerWithMessage:(IMMessage *)message;
@end
