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
    
//    [self.identityScope lock];
    
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    [self.dbHelper executeDB:^(FMDatabase *db) {
        
        
        // 采用内级联查询
        NSString *insTableName = [StudentContacts getTableName];
        NSString *query = [NSString stringWithFormat:@"select USERS.rowid, USERS.userId, USERS.userRole, USERS.name, USERS.avatar, USERS.nameHeader, \
                           STUDENTCONTACTS.remarkName, STUDENTCONTACTS.remarkHeader \
                           from %@ INNER JOIN %@ ON USERS.userId=%@.contactId and \
                           USERS.userRole=%@.contactRole where %@.userId=%lld and %@.contactRole=%ld", [User getTableName], insTableName, insTableName, insTableName,insTableName, userId, insTableName, (long)contactRole];
        
        FMResultSet *set = [db executeQuery:query];
        
        
        [self.imStroage.userDao.identityScope lock];
        
        while ([set next]) {
            int64_t userId = [set longLongIntForColumnIndex:1];
            IMUserRole userRole = [set longForColumnIndex:2];
            
            NSString *key = [NSString stringWithFormat:@"%lld-%ld", userId, (long)userRole];
            User *user = [self.imStroage.userDao.identityScope objectByKey:key lock:NO];
            
            if (! user) {
                user = [[User alloc] init];
            }
            
            user.rowid = [set longForColumnIndex:0];
            user.userId = userId;
            user.userRole = userRole;
            user.name = [set stringForColumnIndex:3];
            user.avatar = [set stringForColumnIndex:4];
            user.nameHeader = [set stringForColumnIndex:5];
            user.remarkName = [set stringForColumnIndex:6];
            user.remarkHeader = [set stringForColumnIndex:7];
            
            [self.imStroage.userDao attachEntityKey:key entity:user lock:NO];
            
            [users addObject:user];
        }
        
        [self.imStroage.userDao.identityScope unlock];
        
        [set close];
    }];
    
    return users;
}

- (StudentContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner
{
    if (owner.userRole != eUserRole_Student) return nil;
    
    NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contactId, (long)contactRole];
    
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
    StudentContacts *_contact = [self loadContactId:contact.contactId contactRole:contact.contactRole owner:owner];
    if (_contact == nil)
    {
        [self.dbHelper insertToDB:contact];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" insert " class:[StudentContacts class]];
        NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId,contact.contactId, (long)contact.contactRole];
        [self attachEntityKey:key entity:contact lock:YES];
    }
    else
    {
        _contact.createTime = contact.createTime;
        _contact.remarkName = contact.remarkName;
        _contact.remarkHeader = contact.remarkHeader;
        [self.dbHelper updateToDB:_contact where:nil];
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
