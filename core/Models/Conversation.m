//
//  Conversation.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "Conversation.h"

@implementation Conversation

- (instancetype)initWithOwnerId:(int64_t)ownerId
                      ownerRole:(IMUserRole)ownerRole
                           toId:(int64_t)toId
                         toRole:(IMUserRole)toRole
                  lastMessageId:(NSString *)lastMessageId
                       chatType:(IMChatType)chatType
{
    self = [super init];
    if (self)
    {
        _ownerId = ownerId;
        _ownerRole = ownerRole;
        _toId = toId;
        _toRole = toRole;
        _lastMessageId = lastMessageId;
        _chat_t = chatType;
    }

    return self;
}

+ (NSString *)getTableName
{
    return @"CONVERSATION";
}

+ (NSDictionary *)getTableMapping
{
    return @{@"ownerId":@"ownerId",
             @"ownerRole":@"ownerRole",
             @"toId":@"toId",
             @"toRole":@"toRole",
             @"lastMessageId":@"lastMessageId",
             @"chat_t":@"chat_t",
             @"unReadNum":@"unReadNum",
             @"status":@"status",
             @"firstMsgId":@"firstMsgId"
             };
}

@end

