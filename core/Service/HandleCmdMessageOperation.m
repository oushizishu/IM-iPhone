//
//  HandleCmdMessageOperation.m
//  Pods
//
//  Created by 杨磊 on 15/11/3.
//
//

#import "HandleCmdMessageOperation.h"
#import "IMEnvironment.h"
#import "NSString+Json.h"

#define ACTION_CMD_NEW_GROUP_NOTICE     @"new_group_notice"

@interface HandleCmdMessageOperation()

@property (nonatomic) SEL resultSelector;
@end

@implementation HandleCmdMessageOperation


- (void)doOperationOnBackground
{
   IMCmdMessageBody *messageBody = (IMCmdMessageBody *)self.message.messageBody;
    NSDictionary *dic = messageBody.payload;
    NSString *action  = dic[@"action"];
    
    if ([action isEqualToString:ACTION_CMD_NEW_GROUP_NOTICE]) {
        self.resultSelector = [self dealNewGRoupNotice:messageBody service:self.imService];
    }
    
}

- (void)doAfterOperationOnMain
{
    if (self.resultSelector && [self.imService respondsToSelector:self.resultSelector]) {
        [self.imService performSelector:self.resultSelector];
    }
}

- (SEL)dealNewGRoupNotice:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    NSDictionary *notice = [messageBody.payload[@"notice"] jsonValue];
    
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    
    int64_t groupId = [[notice objectForKey:@"group_id"] longLongValue];
    NSString *content = [notice objectForKey:@"content"];
    NSString *objectkey = [NSString stringWithFormat:@"NewGroupNotice_%lld",groupId];
    [userDefaultes setObject:content forKey:objectkey];
    [userDefaultes synchronize];
    
    return @selector(notifyNewGroupNotice);
    
}


@end
