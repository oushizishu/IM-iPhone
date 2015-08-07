//
//  Conversation.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "Conversation.h"

@implementation Conversation

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
             };
}

@end

