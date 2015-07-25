//
//  BJChatInfo.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import <User.h>
#import <Group.h>
#import <Conversation.h>
@interface BJChatInfo : NSObject
@property (nonatomic, strong) User *chatToUser;
@property (nonatomic, strong) Group *chatToGroup;
@property (nonatomic, assign) IMChatType chat_t;

- (int64_t)getToId;
- (IMUserRole)getToRole;

- (instancetype)initWithUser:(User *)user;
- (instancetype)initWithGroup:(Group *)group;
- (instancetype)initWithConversation:(Conversation *)conversation;
@end
