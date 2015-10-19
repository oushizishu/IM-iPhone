//
//  InstitutionContactDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "InstitutionContactDao.h"
#import "User.h"
#import "BJIMStorage.h"


@implementation InstitutionContactDao

- (NSArray *)loadAll:(int64_t)userId role:(IMUserRole)contactRole
{
    
    //千万不要加这个锁， 会和 FMDB 中得 ThreadLock 相互造成死锁
//    [self.identityScope lock];
    
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    [self.dbHelper executeDB:^(FMDatabase *db) {
        // 采用内级联查询
        NSString *insTableName = [InstitutionContacts getTableName];
        NSString *query = [NSString stringWithFormat:@"select USERS.rowid, USERS.userId, USERS.userRole, USERS.name, USERS.avatar, USERS.nameHeader, \
                           INSTITUTIONCONTACTS.remarkName, INSTITUTIONCONTACTS.remarkHeader \
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
    
//    NSString *query = [NSString stringWithFormat:@" userId=%lld and contactRole=%ld", userId, (long)contactRole];
//    
//    NSArray *array = [self.dbHelper search:[InstitutionContacts class] where:query orderBy:nil offset:0 count:0];
//    
//    [[DaoStatistics sharedInstance] logDBOperationSQL:query class:[InstitutionContacts class]];
//    
//    NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:[array count]];
//    for (NSInteger index = 0; index < [array count]; ++ index)
//    {
//        InstitutionContacts *item = (InstitutionContacts *)[array objectAtIndex:index];
//        NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", userId, item.contactId, (long)item.contactRole];
//        [self attachEntityKey:key entity:item lock:NO];
//        
//        User *user = [self.imStroage.userDao loadUser:item.contactId role:item.contactRole];
//        user.remarkName = item.remarkName;
//        user.remarkHeader = item.remarkHeader;
//        [users addObject:user];
//    }
    
//    [self.identityScope unlock];
    return users;
}

- (InstitutionContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner
{
    if (owner.userRole != eUserRole_Institution) return nil;
    
    NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contactId, (long)contactRole];
    
    InstitutionContacts *contact = [self.identityScope objectByKey:key lock:YES];
    
    if (! contact)
    {
       NSString *queryString = [NSString stringWithFormat:@"userId=%lld AND contactId=%lld AND contactRole=%ld", owner.userId, contactId, (long)contactRole];
        contact = [self.dbHelper searchSingle:[InstitutionContacts class] where:queryString orderBy:nil];
        [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[InstitutionContacts class]];
        if (contact)
        {
            [self attachEntityKey:key entity:contact lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[InstitutionContacts class]];
    }
    
    return contact;
}

- (void)insertOrUpdateContact:(InstitutionContacts *)contact owner:(User *)owner
{
    if ([self loadContactId:contact.contactId contactRole:contact.contactRole owner:owner] == nil)
    {
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"insert " class:[InstitutionContacts class]];
        [self.dbHelper insertToDB:contact];
        NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contact.contactId, (long)contact.contactRole];
        [self attachEntityKey:key entity:contact lock:YES];
    }
}

- (void)deleteAllContacts:(User *)owner
{
    if (owner.userRole != eUserRole_Institution) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld", owner.userId];
    [self.dbHelper deleteWithClass:[InstitutionContacts class] where:sql];
    [[DaoStatistics sharedInstance] logDBOperationSQL:@" delete " class:[InstitutionContacts class]];
    
    [self.identityScope clear];
}

- (void)deleteContactId:(int64_t)contactId contactRole:(IMUserRole)contactRole owner:(User *)owner
{
    if (owner.userRole != eUserRole_Institution) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld and contactId=%lld and contactRole=%ld", owner.userId, contactId, (long)contactRole];
    [self.dbHelper deleteWithClass:[InstitutionContacts class] where:sql];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:@" delete " class:[InstitutionContacts class]];
    
    NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contactId, (long)contactRole];
   
    InstitutionContacts *contact = [self.identityScope objectByKey:key lock:YES];
    
    if (contact)
    {
        [self detach:key];
    }
}

- (BOOL)isStanger:(User *)contact withOwner:(User *)owner
{
    InstitutionContacts *institution = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    if (institution == nil) {
        return YES;
    }
    
    if ((institution.focusType == eIMFocusType_None && institution.tinyFoucs == eIMTinyFocus_None) ||
        (institution.focusType == eIMFocusType_Passive && institution.tinyFoucs == eIMTinyFocus_None)) {
        return YES;
    }
    return NO;
}
@end
