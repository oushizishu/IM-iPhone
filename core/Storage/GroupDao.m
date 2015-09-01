//
//  GroupDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "GroupDao.h"

@implementation GroupDao

- (Group *)load:(int64_t)groupId
{
    Group *group = [self.identityScope objectByKey:@(groupId) lock:YES];
    
    if (! group)
    {
        group = [self.dbHelper searchSingle:[Group class] where:[NSString stringWithFormat:@"groupId=%lld", groupId] orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"groupId" class:[Group class]];
        
        if (group)
        {
            [self attachEntityKey:@(group.groupId) entity:group lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[Group class]];
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

//- (void)deleteAll:(User *)user
//{
//
//}
@end
