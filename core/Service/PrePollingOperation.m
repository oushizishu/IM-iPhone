//
//  PrePollingOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/21.
//
//

#import "PrePollingOperation.h"
#import "BJIMService.h"
#import "IMEnvironment.h"
#import "User.h"
#import "Group.h"

@interface PrePollingOperation()

@property (nonatomic, assign) int64_t max_msg_id;
@property (nonatomic, copy) NSString *groups_last_msg_id;
@property (nonatomic, copy) NSString *excludeUserMsgIds;

@end

@implementation PrePollingOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    
    User *owner = [IMEnvironment shareInstance].owner;
    
    self.max_msg_id = (int64_t)[self.imService.imStorage queryChatLastMsgIdOwnerId:owner.userId ownerRole:owner.userRole];
    
    NSArray *excludeUserMsgs = [self.imService.imStorage queryChatExludeMessagesMaxMsgId:self.max_msg_id];
    
    NSMutableString *__excludeUserMsgIds = [[NSMutableString alloc] init];
    for (NSInteger index = 0; index < [excludeUserMsgs count]; ++ index)
    {
        IMMessage *__message = [excludeUserMsgs objectAtIndex:index];
        [__excludeUserMsgIds appendFormat:@"%lld,", (int64_t)__message.msgId];
    }
    
    self.excludeUserMsgIds = __excludeUserMsgIds;
    
    NSArray *groups = [self.imService.imStorage queryGroupsWithUser:owner];
    
    NSMutableArray *lastGroupMsgIds = [[NSMutableArray alloc] initWithCapacity:[groups count]];
    for (NSInteger index = 0; index < [groups count]; ++ index)
    {
        Group *group = [groups objectAtIndex:index];
        int64_t groupLastMsgId = (int64_t)[self.imService.imStorage queryGroupChatLastMsgId:group.groupId withoutSender:owner.userRole sendRole:owner.userRole];
        
        NSArray *excludeGroupMsgs = [self.imService.imStorage queryGroupChatExcludeMsgs:group.groupId maxMsgId:groupLastMsgId];
        
        NSMutableString *excludeGroupMsgIds = [[NSMutableString alloc] init];
        for (IMMessage *msg in excludeGroupMsgs) {
            [excludeGroupMsgIds appendFormat:@"%lld,", (int64_t)msg.msgId];
        }
        
        
        NSDictionary *dic = @{@"group_id":[NSString stringWithFormat:@"%lld", group.groupId],
                              @"last_msg_id":[NSString stringWithFormat:@"%lld", groupLastMsgId],
                              @"exclude_msg_ids": excludeGroupMsgIds};
        [lastGroupMsgIds addObject:dic];
    }
    
    if ([lastGroupMsgIds count] > 0)
    {
        NSError *error ;
        NSData *data = [NSJSONSerialization dataWithJSONObject:lastGroupMsgIds options:0 error:&error];
        self.groups_last_msg_id = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

- (void)doAfterOperationOnMain
{
    if (self.imService == nil) return;
    [self.imService.imEngine postPollingRequest:self.max_msg_id excludeUserMsgs:self.excludeUserMsgIds groupsLastMsgIds:self.groups_last_msg_id currentGroup:0];
}
@end
