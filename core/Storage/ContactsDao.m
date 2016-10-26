//
//  ContactsDao.m
//  Pods
//
//  Created by 杨磊 on 16/3/7.
//
//

#import "ContactsDao.h"
#import "User.h"
#import "BJIMStorage.h"

#define UNINVALID_USER_ROLE     -99999

@implementation ContactsDao

- (NSArray<User *> *)loadAll:(User *)owner role:(IMUserRole)contactRole
{
    return [self loadAll:owner role:contactRole relation:eUserRelation_normal];
}

- (NSArray<User *> *)loadAll:(User *)owner role:(IMUserRole)contactRole relation:(IMUserRelation)relation
{
    
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    [self.dbHelper executeDB:^(FMDatabase *db) {
        // 采用内级联查询
        NSString *contactTableName = [Contacts getTableName];
        NSString *userTableName = [User getTableName];
        
        NSMutableString *query = [[NSMutableString alloc] init];
        // 查询条件 user 表字段
        [query appendFormat:@"select %@.rowid, %@.userId, %@.userRole, %@.name, %@.avatar, %@.nameHeader, ",
                        userTableName, userTableName, userTableName, userTableName, userTableName, userTableName];
        // 查询条件 contacts 表字段
        [query appendFormat:@" %@.remarkName, %@.remarkHeader, %@.relation, ", contactTableName, contactTableName, contactTableName];
        
        // 增加 user.onlineStatus
        [query appendFormat:@" %@.onlineStatus", userTableName];
        // 表级联
        [query appendFormat:@" from %@ INNER JOIN %@ ", userTableName, contactTableName];
        // 级联条件
        [query appendFormat:@" ON %@.userId=%@.contactId and %@.userRole=%@.contactRole", userTableName, contactTableName,
            userTableName, contactTableName];
        [query appendString:@" where "];
        // where 条件。 contact 表
        [query appendFormat:@"%@.userId=%lld and %@.userRole=%ld" ,
                contactTableName, owner.userId, contactTableName, owner.userRole];
        
        if (contactRole != UNINVALID_USER_ROLE) {
            [query appendFormat:@" and %@.contactRole=%ld", contactTableName, contactRole];
        }
        // 未拉黑或者被拉黑
        [query appendFormat:@" and %@.relation=%ld", contactTableName, relation];
       
        FMResultSet *set = [db executeQuery:query];
        
        
        [self.imStroage.userDao.identityScope lock];
        
        while ([set next]) {
            int64_t userId =[set longLongIntForColumnIndex:1];
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
            user.relation = [set intForColumnIndex:8];
            user.onlineStatus = [set intForColumnIndex:9];
            
            [self.imStroage.userDao attachEntityKey:key entity:user lock:NO];
            
            [users addObject:user];
        }
        
        [self.imStroage.userDao.identityScope unlock];
        
        [set close];
    }];
    return users;
}

- (Contacts *)loadContactId:(int64_t)contactId contactRole:(IMUserRole)contactRole owner:(User *)owner
{
    NSString *key = [NSString stringWithFormat:@"%lld-%ld-%lld-%ld", owner.userId, owner.userRole, contactId, (long)contactRole];
    Contacts *contact = (Contacts *)[self.identityScope objectByKey:key lock:YES];
    
    if (! contact)
    {
        NSString *queryString = [NSString stringWithFormat:@"userId=%lld AND userRole=%ld AND contactId=%lld AND contactRole=%ld", owner.userId, owner.userRole, contactId, (long)contactRole];
        contact = [self.dbHelper searchSingle:[Contacts class] where:queryString orderBy:nil];
        
        if (contact)
        {
            [self attachEntityKey:key entity:contact lock:YES];
        }
    }
    
    return contact;
}

- (void)insertOrUpdateContact:(User *)contact owner:(User *)owner
{
    Contacts *_contact = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    NSString *key = [NSString stringWithFormat:@"%lld-%ld-%lld-%ld", owner.userId, owner.userRole, contact.userId, (long)contact.userRole];
    
    if (_contact == nil)
    {
        _contact = [[Contacts alloc] init];
        _contact.userId = owner.userId;
        _contact.userRole = owner.userRole;
        _contact.contactId = contact.userId;
        _contact.contactRole = contact.userRole;
        _contact.createTime = contact.createTime;
        _contact.remarkName = contact.remarkName;
        _contact.remarkHeader = contact.remarkHeader;
        [self.dbHelper insertToDB:_contact];
        
        [self attachEntityKey:key entity:_contact lock:YES];
    }
    else
    {
        _contact.createTime = contact.createTime;
        _contact.remarkName = contact.remarkName;
        _contact.remarkHeader = contact.remarkHeader;
        [self.dbHelper updateToDB:_contact where:nil];
        [self attachEntityKey:key entity:_contact lock:YES];
    }
}

- (void)deleteAllContacts:(User *)owner
{
    NSString *sql = [NSString stringWithFormat:@"userId=%lld and userRole=%ld", owner.userId, owner.userRole];
    [self.dbHelper deleteWithClass:[Contacts class] where:sql];
    [self.identityScope clear];
}

- (void)deleteContactId:(int64_t)contactId contactRole:(IMUserRole)contactRole owner:(User *)owner
{
    NSString *sql = [NSString stringWithFormat:@"userId=%lld and userRole=%ld and contactId=%lld and contactRole=%ld", owner.userId, owner.userRole, contactId, (long)contactRole];
    [self.dbHelper deleteWithClass:[Contacts class] where:sql];
    
    NSString *key = [NSString stringWithFormat:@"%lld-%ld-%lld-%ld", owner.userId, owner.userRole, contactId, (long)contactRole];
    Contacts *contact = [self.identityScope objectByKey:key lock:YES];
    
    if (contact)
    {
        [self detach:key];
    }
}

- (BOOL)hasContactOwner:(User *)owner contact:(User *)contact
{
    Contacts *_contact = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    return (_contact != nil);
}

#pragma mark - 黑名单 api
- (void)addBlack:(User *)contact owner:(User *)owner
{
    Contacts *_contact = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    if (_contact == nil) {
        [self insertOrUpdateContact:contact owner:owner];
        _contact = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    }
    
    _contact.relation |= eUserRelation_black_active;
    [self.dbHelper updateToDB:_contact where:nil];
    contact.relation = _contact.relation;
    [self.imStroage.userDao insertOrUpdateUser:contact];
}

- (void)removeBlack:(User *)contact owner:(User *)owner
{
    Contacts *_contact = [self loadContactId:contact.userId contactRole:contact.userRole
                                       owner:owner];
    
    if (_contact == nil) return;
    
    _contact.relation &= ~eUserRelation_black_active;
    [self.dbHelper updateToDB:_contact where:nil];
    contact.relation = _contact.relation;
    [self.imStroage.userDao insertOrUpdateUser:contact];
}

- (void)removeAllBlack:(User *)owner
{
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where relation=%d", [Contacts getTableName],
                          eUserRelation_black_active];
    
    [self.dbHelper executeSQL:deleteSql arguments:nil];
    [self clear];
}

- (NSArray<User *> *)loadAllBlack:(User *)owner
{
    return [self loadAll:owner role:(IMUserRole)UNINVALID_USER_ROLE relation:eUserRelation_black_active];
}

@end
