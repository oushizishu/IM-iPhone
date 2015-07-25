//
//  ChatViewController.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Conversation.h>
@interface BJChatViewController : UIViewController
- (instancetype)initWithConversation:(Conversation *)conversation;
@end
