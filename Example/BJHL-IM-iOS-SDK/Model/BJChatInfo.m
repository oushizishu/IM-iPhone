//
//  BJChatInfo.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInfo.h"
#import <BJIMConstants.h>
#import <Conversation+DB.h>
@implementation BJChatInfo

- (instancetype)initWithUser:(User *)user
{
    self = [super init];
    if (self) {
        _chat_t = eChatType_Chat;
        _chatToUser = user;
    }
    return self;
}

- (instancetype)initWithGroup:(Group *)group
{
    self = [super init];
    if (self) {
        _chat_t = eChatType_GroupChat;
        _chatToGroup = group;
    }
    return self;
}

- (instancetype)initWithConversation:(Conversation *)conversation;
{
    if (conversation.chat_t == eChatType_Chat) {
        self = [self initWithUser:conversation.chatToUser];
    }
    else{
        self = [self initWithGroup:conversation.chatToGroup];
    }
    if (self) {
        
    }
    return self;
}

- (int64_t)getToId;
{
    if (self.chat_t == eChatType_Chat) {
        return self.chatToUser.userId;
    }
    else
        return self.chatToGroup.groupId;
}

- (IMUserRole)getToRole;
{
    if (self.chat_t == eChatType_Chat) {
        return self.chatToUser.userRole;
    }
    else
        return eUserRole_Anonymous;
}

@end
