//
//  GroupMemberDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "GroupMemberDao.h"
#import "BJIMStorage.h"

@implementation GroupMemberDao

- (GroupMember *)loadMember:(int64_t)userId userRole:(IMUserRole)userRole groupId:(int64_t)groupId
{
    GroupMember *member = [self.identityScope objectByCondition:^BOOL(id key, id item) {
        GroupMember *_member = (GroupMember *)item;
        return (_member.userId == userId && _member.userRole == userRole && _member.groupId == groupId);
    } lock:YES];
    
    if (! member)
    {
        NSString *queryString = [NSString stringWithFormat:@" groupId=%lld AND userId=%lld and userRole=%ld",groupId, userId, (long)userRole];
        member = [self.dbHelper searchSingle:[GroupMember class] where:queryString orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" groupId and userId and userRole" class:[GroupMemberDao class]];
        if (member)
        {
            [self attachEntityKey:@(member.rowid) entity:member lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[GroupMemberDao class]];
    }
    
    return member;
}

- (void)insertOrUpdate:(GroupMember *)groupMember
{
    GroupMember *_member = [self loadMember:groupMember.userId userRole:groupMember.userRole groupId:groupMember.groupId];
    if (_member)
    {
        groupMember.rowid = _member.rowid;
        [self.dbHelper updateToDB:groupMember where:nil];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"update" class:[GroupMemberDao class]];
    }
    else
    {
        [self.dbHelper insertToDB:groupMember];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"insert" class:[GroupMemberDao class]];
    }
    [self attachEntityKey:@(groupMember.rowid) entity:groupMember lock:YES];
}

- (void)deleteGroupMembers:(int64_t)groupId
{
    NSString *query = [NSString stringWithFormat:@" groupId=%lld ",groupId];
    [self.dbHelper deleteWithClass:[GroupMember class] where:query];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"delete" class:[GroupMemberDao class]];
    
    [self.identityScope lock];
    
    __block NSMutableArray *array = [NSMutableArray array];
    [self.identityScope objectByCondition:^BOOL(id key, id item) {
        GroupMember *member = (GroupMember *)item;
        if (member.groupId == groupId)
        {
            [array addObject:member];
        }
        return NO;
    } lock:NO];
    
    for (NSInteger index  = 0; index < [array count]; ++ index) {
        GroupMember *member = [array objectAtIndex:index];
        [self detach:@(member.rowid) lock:NO];
    }
    
    [self.identityScope unlock];
}

- (void)deleteGroupMember:(int64_t)groupId user:(User *)user
{
    NSString *queryString = [NSString stringWithFormat:@" groupId=%lld AND userId=%lld and userRole=%ld",groupId, user.userId, (long)user.userRole];
    [self.dbHelper deleteWithClass:[GroupMember class] where:queryString];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"delete" class:[GroupMemberDao class]];
    
    GroupMember *member = [self.identityScope objectByCondition:^BOOL(id key, id item) {
        GroupMember *_member = (GroupMember *)item;
        return (_member.userId == user.userId && _member.userRole == user.userRole && _member.groupId == groupId);
    } lock:YES];
    
    if (member)
    {
        [self detach:@(member.rowid)];
    }
}

- (void)deleteUserGroupMember:(User *)user
{
     NSString *query = [NSString stringWithFormat:@" userId=%lld and userRole=%ld", user.userId, (long)user.userRole];
    [self.dbHelper deleteWithClass:[GroupMember class] where:query];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"delete" class:[GroupMemberDao class]];
    
    [self.identityScope lock];
    
    __block NSMutableArray *array = [NSMutableArray array];
    [self.identityScope objectByCondition:^BOOL(id key, id item) {
        GroupMember *member = (GroupMember *)item;
        if (member.userId == user.userId && member.userRole == user.userRole)
        {
            [array addObject:member];
        }
        return NO;
    } lock:NO];
    
    for (NSInteger index  = 0; index < [array count]; ++ index) {
        GroupMember *member = [array objectAtIndex:index];
        [self detach:@(member.rowid) lock:NO];
    }
    
    [self.identityScope unlock];
}

- (NSArray *)loadAllGroups:(User *)user
{
    
    NSMutableArray *groups = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@" userId=%lld and userRole=%ld", user.userId, (long)user.userRole];
    NSArray *array = [self.dbHelper search:[GroupMember class] where:query orderBy:nil offset:0 count:0];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"loadAll  userId and userRole" class:[GroupMemberDao class]];
    
    [self.identityScope lock];
    for (NSInteger index = 0; index < array.count; ++ index)
    {
        GroupMember *member = [array objectAtIndex:index];
        [self attachEntityKey:@(member.rowid) entity:member lock:NO];
        
        Group *group = [self.imStroage.groupDao load:member.groupId];
        if (group)
        {
            group.remarkName = member.remarkName;
            group.remarkHeader = member.remarkHeader;
            group.pushStatus = member.pushStatus;
            [groups addObject:group];
        }
    }
    [self.identityScope unlock];

    return groups;
}

@end
