//
//  StudentContactDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "StudentContactDao.h"
#import "User.h"
#import "BJIMStorage.h"

@implementation StudentContactDao
- (NSArray *)loadAll:(int64_t)userId role:(IMUserRole)contactRole
{
    
    [self.identityScope lock];
    
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    // 采用内级联查询
    NSString *insTableName = [StudentContacts getTableName];
    NSString *query = [NSString stringWithFormat:@"select USERS.rowid, USERS.userId, USERS.userRole, USERS.name, USERS.avatar, USERS.nameHeader, \
                       STUDENTCONTACTS.remarkName, STUDENTCONTACTS.remarkHeader \
                       from %@ INNER JOIN %@ ON USERS.userId=%@.contactId and \
                       USERS.userRole=%@.contactRole where %@.userId=%lld and %@.contactRole=%ld", [User getTableName], insTableName, insTableName, insTableName,insTableName, userId, insTableName, (long)contactRole];
    
    [self.dbHelper executeForTransaction:^BOOL(LKDBHelper *helper) {
        [helper executeDB:^(FMDatabase *db) {
            FMResultSet *set = [db executeQuery:query];
            
            while ([set next]) {
                User *user = [[User alloc] init];
                user.rowid = [set longForColumnIndex:0];
                user.userId = [set longLongIntForColumnIndex:1];
                user.userRole = [set longForColumnIndex:2];
                user.name = [set stringForColumnIndex:3];
                user.avatar = [set stringForColumnIndex:4];
                user.nameHeader = [set stringForColumnIndex:5];
                user.remarkName = [set stringForColumnIndex:6];
                user.remarkHeader = [set stringForColumnIndex:7];
                
                NSString *key = [NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole];
                [self.imStroage.userDao attachEntityKey:key entity:user lock:YES];
                
                [users addObject:user];
            }
            
            [set close];
        }];
        return YES;
    }];
    
//    NSString *query = [NSString stringWithFormat:@" userId=%lld and contactRole=%ld", userId, (long)contactRole];
//    
//    NSArray *array = [self.dbHelper search:[StudentContacts class] where:query orderBy:nil offset:0 count:0];
//    
//    [[DaoStatistics sharedInstance] logDBOperationSQL:query class:[StudentContacts class]];
//    
//     NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:[array count]];
//    for (NSInteger index = 0; index < [array count]; ++ index)
//    {
//        StudentContacts *item = (StudentContacts *)[array objectAtIndex:index];
//        NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", userId, item.contactId, (long)contactRole];
//        [self attachEntityKey:key entity:item lock:NO];
//        
//        User *user = [self.imStroage.userDao loadUser:item.contactId role:item.contactRole];
//        user.remarkName = item.remarkName;
//        user.remarkHeader = item.remarkHeader;
//        [users addObject:user];
//    }
    
    [self.identityScope unlock];
    return users;
}

- (StudentContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner
{
    if (owner.userRole != eUserRole_Student) return nil;
    
    NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contactId, (long)contactRole];
    
//    StudentContacts *contact = (StudentContacts *)[self.identityScope objectByCondition:^BOOL(id key, id item) {
//        StudentContacts *_contact = (StudentContacts *)item;
//        return (_contact.contactId == contactId && _contact.contactRole == contactRole && _contact.userId == owner.userId);
//    } lock:YES];
    
    StudentContacts *contact = [self.identityScope objectByKey:key lock:YES];
    
    if (! contact)
    {
        NSString *queryString = [NSString stringWithFormat:@"userId=%lld AND contactId=%lld AND contactRole=%ld", owner.userId, contactId, (long)contactRole];
        contact = [self.dbHelper searchSingle:[StudentContacts class] where:queryString orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[StudentContacts class]];
        
        if (contact)
        {
            [self attachEntityKey:key entity:contact lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[StudentContacts class]];
    }
    
    return contact;
}

- (void)insertOrUpdateContact:(StudentContacts *)contact owner:(User *)owner
{
    if ([self loadContactId:contact.contactId contactRole:contact.contactRole owner:owner] == nil)
    {
        [self.dbHelper insertToDB:contact];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" insert " class:[StudentContacts class]];
        NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId,contact.contactId, (long)contact.contactRole];
        [self attachEntityKey:key entity:contact lock:YES];
    }
}

- (void)deleteAllContacts:(User *)owner
{
    if (owner.userRole != eUserRole_Student) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld", owner.userId];
    [self.dbHelper deleteWithClass:[StudentContacts class] where:sql];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@" deleteALL " class:[StudentContacts class]];
    
    [self.identityScope clear];
}

- (void)deleteContactId:(int64_t)contactId contactRole:(IMUserRole)contactRole owner:(User *)owner
{
    if (owner.userRole != eUserRole_Student ) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld and contactId=%lld and contactRole=%ld", owner.userId, contactId, (long)contactRole];
    [self.dbHelper deleteWithClass:[StudentContacts class] where:sql];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:@" delete " class:[StudentContacts class]];
    
    NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contactId, (long)contactRole];
    
    StudentContacts *contact = [self.identityScope objectByKey:key lock:YES];
    
    if (contact)
    {
        [self detach:key];
    }
}
@end
