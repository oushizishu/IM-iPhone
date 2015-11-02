//
//  GroupDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "GroupDao.h"
#import "BJIMStorage.h"
#import "IMEnvironment.h"

@implementation GroupDao

- (Group *)load:(int64_t)groupId
{
    Group *group = [self.identityScope objectByKey:@(groupId) lock:YES];
    
    if (! group)
    {
        group = [self.dbHelper searchSingle:[Group class] where:[NSString stringWithFormat:@"groupId=%lld", groupId] orderBy:nil];
        
        User *owner = [IMEnvironment shareInstance].owner;;
       GroupMember *member = [self.imStroage.groupMemberDao loadMember:owner.userId userRole:owner.userRole groupId:group.groupId];
        
        if (member) {
            group.remarkName = member.remarkName;
            group.remarkHeader = member.remarkHeader;
            group.pushStatus = member.pushStatus;
            
            group.isAdmin =  member.isAdmin;
            group.createTime =  member.createTime;
            
            group.msgStatus =  member.msgStatus;
            group.canLeave =  member.canLeave;//是否能退出
            group.canDisband =  member.canDisband;//是否能解散
            
            group.joinTime =  member.joinTime;
        }
        
    
        
        if (group)
        {
            [self attachEntityKey:@(group.groupId) entity:group lock:YES];
        }
    }

    return group;
}

- (void)insertOrUpdate:(Group *)group
{
    Group *_group = [self load:group.groupId];
    
    if (!_group)
    {
        [self.dbHelper insertToDB:group];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" insert " class:[Group class]];
    }
    else
    {
        group.rowid = _group.rowid;
        [self.dbHelper updateToDB:group where:[NSString stringWithFormat:@"groupId=%lld", group.groupId]];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" update " class:[Group class]];
    }
    
    [self attachEntityKey:@(group.groupId) entity:group lock:YES];
}

- (void)deleteGroup:(int64_t)groupId
{
    [self.dbHelper deleteWithClass:[Group class] where:[NSString stringWithFormat:@" groupId=%lld", groupId]];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"delete" class:[Group class]];
    
    [self detach:@(groupId)];
}

//- (void)attachEntityKey:(id)key entity:(id)entity lock:(BOOL)lock
//{
//    if (lock)
//    {
//        [self.identityScope lock];
//    }
//    
//    Group *group = [self.identityScope objectByKey:key lock:NO];
//    if (group)
//    {
//        Group *_group = (Group *)entity;
//        
//        group.groupName = _group.groupName;
//        group.avatar = _group.avatar;
//        group.descript = _group.descript;
//        group.isPublic = _group.isPublic;
//        group.maxusers = _group.maxusers;
//        group.memberCount = _group.memberCount;
//        group.status = _group.status;
//        group.pushStatus = _group.pushStatus;
//        group.msgStatus = _group.msgStatus;
//        group.canLeave = _group.canLeave;
//        group.canDisband = _group.canDisband;
//        group.nameHeader = _group.nameHeader;
//        group.remarkName = _group.remarkName;
//        group.remarkHeader = _group.remarkHeader;
//        group.lastMessageId = _group.lastMessageId;
//        group.startMessageId = _group.startMessageId;
//        group.endMessageId = _group.endMessageId;
//    }
//    else
//    {
//        [self.identityScope appendObject:entity key:key lock:NO];
//    }
//    
//    if (lock)
//    {
//        [self.identityScope unlock];
//    }
//}

//- (void)deleteAll:(User *)user
//{
//
//}
@end
