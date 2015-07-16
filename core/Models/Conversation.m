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


@end
