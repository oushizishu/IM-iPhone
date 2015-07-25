//
//  ChatInputBaseViewController.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Conversation.h>
#import "BJSendMessageHelper.h"

@interface BJChatInputBaseViewController : UIViewController
@property (strong, readonly, nonatomic) Conversation *conversation;
- (instancetype)initWithConversation:(Conversation *)conversation;
@end