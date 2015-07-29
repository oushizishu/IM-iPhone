/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "UIResponder+Router.h"
NSString *const kRouterEventImageBubbleTapEventName = @"kRouterEventImageBubbleTapEventName";
NSString *const kRouterEventAudioBubbleTapEventName = @"kRouterEventAudioBubbleTapEventName";
NSString *const kRouterEventCardEventName = @"kRouterEventChatCellBubbleCardEventName";
NSString *const kRouterEventUserInfoObject = @"kRouterEventUserInfoObject";
NSString *const kRouterEventChatCellBubbleTapEventName = @"kRouterEventChatCellBubbleTapEventName";
NSString *const kResendButtonTapEventName = @"kResendButtonTapEventName";

NSString *const kSendNewMessageEventName = @"kSendNewMessageEventName";
NSString *const kRouterEventLinkName = @"kRouterEventLinkName";

@implementation UIResponder (Router)

- (void)routerEventWithName:(NSString *)eventName userInfo:(NSDictionary *)userInfo
{
    [[self nextResponder] routerEventWithName:eventName userInfo:userInfo];
}

@end
