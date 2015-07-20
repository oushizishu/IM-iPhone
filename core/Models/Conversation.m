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

- (NSMutableArray *)messages
{
    if (_messages == nil)
    {
    }
    return _messages;
}

/*
 @property (nonatomic, assign) int64_t ownerId;
 @property (nonatomic, assign) IMUserRole ownerRole;
 @property (nonatomic, assign) int64_t toId;
 @property (nonatomic, assign) IMUserRole toRole;
 @property (nonatomic, assign) int64_t lastMsgRowId;
 @property (nonatomic, assign) IMChatType chat_t;
 @property (nonatomic, assign) NSInteger unReadNum;
 */
+ (NSDictionary *)getTableMapping
{
    return @{@"ownerId":@"ownerId",
             @"ownerRole":@"ownerRole",
             @"toId":@"toId",
             @"toRole":@"toRole",
             @"lastMsgRowId":@"lastMsgRowId",
             @"chat_t":@"chat_t",
             @"unReadNum":@"unReadNum",
             };
}

@end

