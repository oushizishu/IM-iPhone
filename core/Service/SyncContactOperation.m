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
#import "Contacts.h"
#import "GroupMember.h"
@implementation SyncContactOperation
- (void)doOperationOnBackground
{
    User *currentUser = [[IMEnvironment shareInstance] owner];
    NSDictionary *dictionary = self.contactDictionary;
    [self.imService.imStorage deleteMyContactWithUser:currentUser];
    
    if ([dictionary  isKindOfClass:[NSDictionary class]]) {
        NSArray *groupList = [dictionary  objectForKey:@"group_list"];
        NSArray *organizationList = [dictionary  objectForKey:@"organization_list"];
        NSArray *studentList = [dictionary  objectForKey:@"student_list"];
        for (NSDictionary *dict  in groupList) {
            Group  *group = [MTLJSONAdapter modelOfClass:[Group class] fromJSONDictionary:dict error:nil];
            if (group) {
                Group *__group = [self.imService.imStorage queryGroupWithGroupId:group.groupId];
                group.isPublic = __group.isPublic;
                group.createTime = __group.createTime;
                group.maxusers = __group.maxusers;
                group.approval = __group.approval;
                group.status   = __group.status;
                group.descript = __group.descript;
                [self.imService.imStorage insertOrUpdateGroup:group];
            }
            GroupMember *member = [self.imService.imStorage queryGroupMemberWithGroupId:group.groupId userId:currentUser.userId userRole:currentUser.userRole];
            if (!member) {
                member = [[GroupMember  alloc] init];
                member.groupId = group.groupId;
                member.userId = currentUser.userId;
                member.userRole = currentUser.userRole;
                [self.imService.imStorage insertGroupMember:member];
            }
        }
        
        for (NSDictionary *dic in organizationList) {
            User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:dic error:nil];
            [self.imService.imStorage insertOrUpdateUser:user];
            [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
            
        }
        for (NSDictionary *dic in studentList) {
            User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:dic error:nil];
            [self.imService.imStorage insertOrUpdateUser:user];
            [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];

        }
    }
}

- (void)doAfterOperationOnMain
{
    
}
@end
