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
    NSString *key = [self getKeyMember:userId userRole:userRole groupId:groupId];
    GroupMember *member = [self.identityScope objectByKey:key lock:YES];
    
    if (! member)
    {
        NSString *queryString = [NSString stringWithFormat:@" groupId=%lld AND userId=%lld and userRole=%ld",groupId, userId, (long)userRole];
        member = [self.dbHelper searchSingle:[GroupMember class] where:queryString orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" groupId and userId and userRole" class:[GroupMemberDao class]];
        if (member)
        {
            [self attachEntityKey:key entity:member lock:YES];
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
    NSString *key = [self getKeyMember:_member.userId userRole:_member.userRole groupId:_member.groupId];
    [self attachEntityKey:key entity:groupMember lock:YES];
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
        NSString *key = [self getKeyMember:member.userId userRole:member.userRole groupId:member.groupId];
        [self detach:key lock:NO];
    }
    
    [self.identityScope unlock];
}

- (void)deleteGroupMember:(int64_t)groupId user:(User *)user
{
    NSString *queryString = [NSString stringWithFormat:@" groupId=%lld AND userId=%lld and userRole=%ld",groupId, user.userId, (long)user.userRole];
    [self.dbHelper deleteWithClass:[GroupMember class] where:queryString];
    
    NSString *key = [self getKeyMember:user.userId userRole:user.userRole groupId:groupId];

    [self detach:key];
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
         NSString *key = [self getKeyMember:member.userId userRole:member.userRole groupId:member.groupId];
        [self detach:key lock:NO];
    }
    
    [self.identityScope unlock];
}

- (NSArray *)loadAllGroups:(User *)user
{
    
    __block NSMutableArray *groups;
    
    NSString *query = [NSString stringWithFormat:@"select IMGROUPS.rowid, IMGROUPS.groupId, IMGROUPS.groupName, IMGROUPS.avatar, GROUPMEMBER.canDisband, GROUPMEMBER.canLeave, GROUPMEMBER.createTime, GROUPMEMBER.isAdmin, GROUPMEMBER.joinTime, GROUPMEMBER.msgStatus, GROUPMEMBER.pushStatus, GROUPMEMBER.remarkHeader, GROUPMEMBER.remarkName from IMGROUPS INNER JOIN GROUPMEMBER on IMGROUPS.groupId=GROUPMEMBER.groupId where GROUPMEMBER.userId=%lld and GROUPMEMBER.userRole=%ld order by GROUPMEMBER.joinTime DESC;", user.userId, user.userRole];
    
    [self.dbHelper executeDB:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:query];
        groups = [self loadAllGroupsFromFMResultSet:set];
        [set close];
    }];

    return groups;
}

- (NSString *)getKeyMember:(int64_t)userId userRole:(IMUserRole)userRole groupId:(int64_t)groupId
{
    return [NSString stringWithFormat:@"%lld-%ld-%lld", userId, (long)userRole, groupId];
}

- (NSArray *)loadAllGroupsFromFMResultSet:(FMResultSet *)set
{
    __block NSMutableArray *array = [[NSMutableArray alloc] init];
    [self.imStroage.groupDao.identityScope lock];
    
    while ([set next]) {
        Group *group = [self loadGroupFromFMResultSet:set];
        [array addObject:group];
    }
    
    [self.imStroage.groupDao.identityScope unlock];
    return array;
}

- (Group *)loadGroupFromFMResultSet:(FMResultSet *)set
{
    Group *group = [[Group alloc] init];
    group.rowid = (NSInteger)[set longForColumnIndex:0];
    group.groupId = [set longForColumnIndex:1];
    group.groupName = [set stringForColumnIndex:2];
    group.avatar = [set stringForColumnIndex:3];
    group.canDisband = [set boolForColumnIndex:4];
    group.canLeave = [set boolForColumnIndex:5];
    group.createTime = [set longForColumnIndex:6];
    group.isAdmin = [set boolForColumnIndex:7];
    group.joinTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:8]];
    group.msgStatus = [set longForColumnIndex:9];
    group.pushStatus = [set longForColumnIndex:10];
    group.remarkHeader = [set stringForColumnIndex:11];
    group.remarkName = [set stringForColumnIndex:12];
    
    [self.imStroage.groupDao attachEntityKey:@(group.groupId) entity:group lock:NO];
   
    return group;
}

@end
