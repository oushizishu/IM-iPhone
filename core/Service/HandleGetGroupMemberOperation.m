//
//  HandleGetGroupMemberOperation.m
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import "HandleGetGroupMemberOperation.h"
#import "GroupMemberListData.h"
#import "GroupMember.h"
#import "BJIMService+GroupManager.h"
@interface HandleGetGroupMemberOperation ()
@property (strong, nonatomic) GroupMemberListData *listData;
@property (nonatomic, weak) BJIMService *imService;
@end

@implementation HandleGetGroupMemberOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSAssert(0, @"不能使用此初始化方法");
    }
    return self;
}

- (instancetype)initWithService:(BJIMService *)service listData:(GroupMemberListData *)listData
{
    self = [super init];
    if (self) {
        _imService = service;
        _listData = listData;
    }
    return self;
}

- (void)doOperationOnBackground;
{
    int64_t groupId = self.listData.groupId;
    NSMutableArray *userList = [[NSMutableArray alloc] initWithCapacity:0];
    for (User *user in self.listData.list) {
        //把群关系写入本地
        GroupMember *member = [self.imService.imStorage.groupMemberDao loadMember:user.userId userRole:user.userRole groupId:groupId];
        if (!member) {
            member = [[GroupMember alloc] init];
            member.userId = user.userId;
            member.userRole = user.userRole;
            member.groupId = groupId;
            [self.imService.imStorage.groupMemberDao insertOrUpdate:member];
        }
        
        //把user信息写入本地
        User *_user = [self.imService.imStorage.userDao loadUser:user.userId role:user.userRole];
        if (! _user) {
            _user = user;
        }
        else
        {
            _user.avatar = user.avatar;
            _user.name = user.name;
            _user.nameHeader = user.nameHeader;
        }
        [userList addObject:_user];
        [self.imService.imStorage.userDao insertOrUpdateUser:_user];
        
    }
    self.listData.list = [userList copy];
}

- (void)doAfterOperationOnMain;
{
    if (self.model) {
        [self.imService notifyGetGroupMembers:self.listData model:self.model error:nil];
    }
    else
    {
        [self.imService notifyGetGroupMembers:self.listData userRole:self.listData.userRole page:self.listData.page groupId:self.listData.groupId error:nil];
    }
 
}

@end
