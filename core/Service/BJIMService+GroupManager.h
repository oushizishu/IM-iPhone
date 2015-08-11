//
//  BJIMService+GroupManager.h
//  Pods
//
//  Created by Randy on 15/8/6.
//
//

#import "BJIMService.h"

@interface BJIMService (GroupManager)
//群组设置
- (void)addGroupManagerDelegate:(id<IMGroupManagerResultDelegate>)delegate;
- (void)getGroupProfile:(int64_t)groupId;
- (void)leaveGroupWithGroupId:(int64_t)groupId;
- (void)disbandGroupWithGroupId:(int64_t)groupId;
- (void)getGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)page;
- (void)changeGroupName:(NSString *)name groupId:(int64_t)groupId;
- (void)setGroupMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId;

#pragma mark - notify
- (void)notifyGetGroupProfile:(int64_t)groupId group:(Group *)group error:(NSError *)error;
- (void)notifyLeaveGroup:(int64_t)groupId error:(NSError *)error;
- (void)notifyDisbandGroup:(int64_t)groupId error:(NSError *)error;
- (void)notifyChangeGroupName:(NSString *)name groupId:(int64_t)groupId error:(NSError *)error;
- (void)notifyGetGroupMembers:(GroupMemberListData *)members userRole:(IMUserRole)userRole page:(NSInteger)page groupId:(int64_t)groupId error:(NSError *)error;
- (void)notifyChangeMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId error:(NSError *)error;
@end
