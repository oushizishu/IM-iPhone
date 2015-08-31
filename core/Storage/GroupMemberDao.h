//
//  GroupMemberDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "IMBaseDao.h"
#import "GroupMember.h"

@interface GroupMemberDao : IMBaseDao

- (GroupMember *)loadMember:(int64_t)userId userRole:(IMUserRole)userRole groupId:(int64_t)groupId;
- (void)insertOrUpdate:(GroupMember *)groupMember;

- (void)deleteGroupMembers:(int64_t)groupId;
- (void)deleteGroupMember:(int64_t)groupId user:(User *)user;
- (void)deleteUserGroupMember:(User *)user;

- (NSArray *)loadAllGroups:(User *)user;

@end
