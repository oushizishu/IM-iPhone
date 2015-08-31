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
        [self.imService.imStorage.groupDao insertOrUpdate:group];
        
        GroupMember *_groupMember = [[GroupMember alloc] init];
        _groupMember.userId = currentUser.userId;
        _groupMember.userRole = currentUser.userRole;
        _groupMember.groupId = group.groupId;
        _groupMember.msgStatus = group.msgStatus;
        _groupMember.canDisband = group.canDisband;
        _groupMember.canLeave = group.canLeave;
        _groupMember.remarkHeader = group.remarkHeader;
        _groupMember.remarkName = group.remarkName;
        _groupMember.pushStatus = group.pushStatus;
        
        [self.imService.imStorage insertOrUpdateGroupMember:_groupMember];
    }
    
    NSArray *organizationList = self.model.organizationList;
    for (User *user in organizationList) {
        [self.imService.imStorage.userDao insertOrUpdateUser:user];
        [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
    }
    
    NSArray *studentList = self.model.studentList;
    for (User *user in studentList) {
        [self.imService.imStorage.userDao insertOrUpdateUser:user];
        [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
    }
    
    NSArray *teacherList = self.model.teacherList;
    for (User *user in teacherList) {
        [self.imService.imStorage.userDao insertOrUpdateUser:user];
        [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
    }
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyContactChanged];
}
@end
