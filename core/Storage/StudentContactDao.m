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
    
//    [self.identityScope unlock];
    return users;
}

- (NSArray *)loadMyAttentions:(int64_t)userId role:(IMUserRole)contactRole
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [self.dbHelper executeDB:^(FMDatabase *db) {
       
        // 采用内级联查询
        NSString *insTableName = [StudentContacts getTableName];
        NSString *query = [NSString stringWithFormat:@"select USERS.rowid, USERS.userId, USERS.userRole, USERS.name, USERS.avatar, USERS.nameHeader, \
                           STUDENTCONTACTS.remarkName, STUDENTCONTACTS.remarkHeader \
                           STUDENTCONTACTS.blackStatus, STUDENTCONTACTS.originType, STUDENTCONTACTS.focusType \
                          STUDENTCONTACTS.tinyFoucs, STUDENTCONTACTS.focusTime,STUDENTCONTACTS.fansTime \
                           from %@ INNER JOIN %@ ON USERS.userId=%@.contactId and \
                           USERS.userRole=%@.contactRole where %@.userId=%lld and \
                           %@.contactRole=%ld and %@.blackStatus!=%ld and %@.focusType=%ld", [User getTableName], insTableName, insTableName, insTableName,insTableName, userId,insTableName,(long)contactRole,insTableName, eIMBlackStatus_Active,insTableName, eIMFocusType_Active];
        
        
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
            
            user.blackStatus = [set longForColumnIndex:8];
            user.originType = [set longForColumnIndex:9];
            user.focusType = [set longForColumnIndex:10];
            user.tinyFocus = [set longForColumnIndex:11];
            user.focusTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:12]];
            user.fansTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:13]];
            
            NSString *key = [NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole];
            [self.imStroage.userDao attachEntityKey:key entity:user lock:YES];
            
            [users addObject:user];
        }
        
        [set close];
    }];
    return users;
}

- (NSArray *)loadMyFans:(int64_t)userId role:(IMUserRole)contactRole
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [self.dbHelper executeDB:^(FMDatabase *db) {
        
        // 采用内级联查询
        NSString *insTableName = [StudentContacts getTableName];
        NSString *query = [NSString stringWithFormat:@"select USERS.rowid, USERS.userId, USERS.userRole, USERS.name, USERS.avatar, USERS.nameHeader, \
                           STUDENTCONTACTS.remarkName, STUDENTCONTACTS.remarkHeader \
                           from %@ INNER JOIN %@ ON USERS.userId=%@.contactId and \
                           USERS.userRole=%@.contactRole where %@.userId=%lld and \
                           %@.contactRole=%ld and %@.blackStatus!=%ld and %@.focusType=%ld", [User getTableName], insTableName, insTableName, insTableName,insTableName, userId,insTableName,(long)contactRole,insTableName, eIMBlackStatus_Passive,insTableName, eIMFocusType_Passive];
        
        
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
    return users;
}

- (NSArray *)loadMyBlackList:(int64_t)userId role:(IMUserRole)contactRole
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [self.dbHelper executeDB:^(FMDatabase *db) {
        
        // 采用内级联查询
        NSString *insTableName = [StudentContacts getTableName];
        NSString *query = [NSString stringWithFormat:@"select USERS.rowid, USERS.userId, USERS.userRole, USERS.name, USERS.avatar, USERS.nameHeader, \
                           STUDENTCONTACTS.remarkName, STUDENTCONTACTS.remarkHeader \
                           from %@ INNER JOIN %@ ON USERS.userId=%@.contactId and \
                           USERS.userRole=%@.contactRole where %@.userId=%lld and \
                           %@.contactRole=%ld and %@.blackStatus=%ld", [User getTableName], insTableName, insTableName, insTableName,insTableName, userId,insTableName,(long)contactRole,insTableName, eIMBlackStatus_Active];
        
        
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


- (BOOL)isStanger:(User *)contact withOwner:(User *)owner
{
    StudentContacts *student = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    if (student == nil) {
        return YES;
    }
    
    if ((student.focusType == eIMFocusType_None && student.tinyFoucs == eIMTinyFocus_None) ||
        (student.focusType == eIMFocusType_Passive && student.tinyFoucs == eIMTinyFocus_None)) {
        return YES;
    }
    return NO;
}

- (IMFocusType)getAttentionState:(User *)contact withOwner:(User *)owner;
{
    StudentContacts *student = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    return student.focusType;
}

- (IMTinyFocus)getTinyFoucsState:(User *)contact withOwner:(User *)owner
{
    StudentContacts *student = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    return student.tinyFoucs;
}

- (void)setContactTinyFoucs:(IMTinyFocus)type contact:(User*)contact  owner:(User *)owner
{
    contact.tinyFocus = type;
    StudentContacts *scontract = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    scontract.tinyFoucs = contact.tinyFocus;
    [self insertOrUpdateContact:scontract owner:owner];
}

- (void)setContactFocusType:(BOOL)opType contact:(User*)contact owner:(User *)owner
{
    if (opType) {
        if (contact.focusType == eIMFocusType_None || contact.focusType == eIMFocusType_Active) {
            contact.focusType = eIMFocusType_Active;
        }else
        {
            contact.focusType = eIMFocusType_Both;
        }
    }else
    {
        if (contact.focusType == eIMFocusType_Both || contact.focusType == eIMFocusType_Passive) {
            contact.focusType = eIMFocusType_Passive;
        }else
        {
            contact.focusType = eIMFocusType_None;
        }
    }
    
    StudentContacts *scontract = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    scontract.focusType = contact.focusType;
    [self insertOrUpdateContact:scontract owner:owner];
}

@end
