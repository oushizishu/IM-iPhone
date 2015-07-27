//
//  SyncContactOperation.m
//  Pods
//
//  Created by 彭碧 on 15/7/21.
//
//

#import "SyncContactOperation.h"
#import "IMEnvironment.h"
#import "BJIMService.h"
#import "GroupMember.h"
@implementation SyncContactOperation
- (void)doOperationOnBackground
{
    User *currentUser = [[IMEnvironment shareInstance] owner];

    [self.imService.imStorage deleteMyContactWithUser:currentUser];
    [self.imService.imStorage deleteMyGroups:currentUser];
    
    
    NSArray *groupList = self.model.groupList;
    for (Group *group  in groupList) {
        Group *__group = [self.imService.imStorage queryGroupWithGroupId:group.groupId];
        if (__group)
        {
            group.isPublic = __group.isPublic;
            group.createTime = __group.createTime;
            group.maxusers = __group.maxusers;
            group.approval = __group.approval;
            group.status   = __group.status;
            group.descript = __group.descript;
        }
        [self.imService.imStorage insertOrUpdateGroup:group];
        
        GroupMember *member = [self.imService.imStorage queryGroupMemberWithGroupId:group.groupId userId:currentUser.userId userRole:currentUser.userRole];
        if (!member) {
            member = [[GroupMember  alloc] init];
            member.groupId = group.groupId;
            member.userId = currentUser.userId;
            member.userRole = currentUser.userRole;
            [self.imService.imStorage insertGroupMember:member];
        }
    }
    
    NSArray *organizationList = self.model.organizationList;
    for (User *user in organizationList) {
        [self.imService.imStorage insertOrUpdateUser:user];
        [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
        
    }
    
    NSArray *studentList = self.model.studentList;
    for (User *user in studentList) {
        [self.imService.imStorage insertOrUpdateUser:user];
        [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
    }
    
    NSArray *teacherList = self.model.teacherList;
    for (User *user in teacherList) {
        [self.imService.imStorage insertOrUpdateUser:user];
        [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
    }
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyContactChanged];
}
@end
