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

@property (nonatomic, copy) NSString *max_msg_id;
@property (nonatomic, copy) NSString *groups_last_msg_id;
@property (nonatomic, copy) NSString *excludeUserMsgIds;

@end

@implementation PrePollingOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    
    [NSThread sleepForTimeInterval:0.3]; // 线程休眠 300ms， 为了防止 messageNew 在同一时刻大量下发，降低服务器压力.
    
    User *owner = [IMEnvironment shareInstance].owner;
    
    self.max_msg_id = [self.imService.imStorage.messageDao queryChatLastMsgIdOwnerId:owner.userId ownerRole:owner.userRole];
    
    NSArray *excludeUserMsgs = [self.imService.imStorage.messageDao queryChatExludeMessagesMaxMsgId:self.max_msg_id];
    
    NSMutableString *__excludeUserMsgIds = [[NSMutableString alloc] init];
    for (NSInteger index = 0; index < [excludeUserMsgs count]; ++ index)
    {
        IMMessage *__message = [excludeUserMsgs objectAtIndex:index];
        [__excludeUserMsgIds appendFormat:@"%lld,", [__message.msgId longLongValue]];
    }
    
    
    NSArray *groups = [self.imService.imStorage.groupMemberDao loadAllGroups:owner];
    
    NSMutableArray *lastGroupMsgIds = [[NSMutableArray alloc] initWithCapacity:[groups count]];
    for (NSInteger index = 0; index < [groups count]; ++ index)
    {
        Group *group = [groups objectAtIndex:index];
        NSString *groupLastMsgId = [self.imService.imStorage.messageDao queryGroupChatLastMsgId:group.groupId withoutSender:owner.userId sendRole:owner.userRole];
        
        NSArray *excludeGroupMsgs = [self.imService.imStorage.messageDao queryGroupChatExcludeMsgs:group.groupId maxMsgId:groupLastMsgId];
       
        for (IMMessage *msg in excludeGroupMsgs) {
            [__excludeUserMsgIds appendFormat:@"%lld,", [msg.msgId longLongValue]];
        }
        
        NSDictionary *dic = @{@"group_id":[NSString stringWithFormat:@"%lld", group.groupId],
                              @"last_msg_id":groupLastMsgId == nil ? @"0": [NSString stringWithFormat:@"%ld", (long)[groupLastMsgId integerValue]]
                              };

        [lastGroupMsgIds addObject:dic];
    }
    
    if ([lastGroupMsgIds count] > 0)
    {
        NSError *error ;
        NSData *data = [NSJSONSerialization dataWithJSONObject:lastGroupMsgIds options:0 error:&error];
        self.groups_last_msg_id = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    self.excludeUserMsgIds = __excludeUserMsgIds;
}

- (void)doAfterOperationOnMain
{
    if (self.imService == nil) return;
    [self.imService.imEngine postPullRequest:[self.max_msg_id longLongValue]
                                excludeUserMsgs:[self.excludeUserMsgIds copy]
                               groupsLastMsgIds:[self.groups_last_msg_id copy]
                                   currentGroup:[IMEnvironment shareInstance].currentChatToGroupId];
}
@end
