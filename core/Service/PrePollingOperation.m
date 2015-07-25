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

@end

@implementation PrePollingOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    
    User *owner = [IMEnvironment shareInstance].owner;
    
    self.max_msg_id = (int64_t)[self.imService.imStorage queryChatLastMsgIdOwnerId:owner.userId ownerRole:owner.userRole];
    
    NSArray *groups = [self.imService.imStorage queryGroupsWithUser:owner];
    
    if ([groups count] == 0) return;
    
    NSMutableArray *lastGroupMsgIds = [[NSMutableArray alloc] initWithCapacity:[groups count]];
    for (NSInteger index = 0; index < [groups count]; ++ index)
    {
        Group *group = [groups objectAtIndex:index];
        int64_t groupLastMsgId = (int64_t)[self.imService.imStorage queryGroupChatLastMsgId:group.groupId withoutSender:owner.userRole sendRole:owner.userRole];
        
        NSDictionary *dic = @{@"group_id":[NSString stringWithFormat:@"%lld", group.groupId],
                              @"last_msg_id":[NSString stringWithFormat:@"%lld", groupLastMsgId]};
        [lastGroupMsgIds addObject:dic];
    }
    
    self.groups_last_msg_id = [lastGroupMsgIds description];
}

- (void)doAfterOperationOnMain
{
    if (self.imService == nil) return;
    [self.imService.imEngine postPollingRequest:self.max_msg_id groupsLastMsgIds:self.groups_last_msg_id currentGroup:0];
}
@end
