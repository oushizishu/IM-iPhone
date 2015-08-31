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
    }
    else
    {
        group.rowid = _group.rowid;
        [self.dbHelper updateToDB:group where:[NSString stringWithFormat:@"groupId=%lld", group.groupId]];
    }
    
    [self attachEntityKey:@(group.groupId) entity:group lock:YES];
}

- (void)deleteGroup:(int64_t)groupId
{
    [self.dbHelper deleteWithClass:[Group class] where:[NSString stringWithFormat:@" groupId=%lld", groupId]];
    
    [self detach:@(groupId)];
}

//- (void)deleteAll:(User *)user
//{
//
//}
@end
