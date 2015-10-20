//
//  TeacherContactDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "TeacherContactDao.h"
#import "User.h"
#import "BJIMStorage.h"

@implementation TeacherContactDao
- (NSArray *)loadAll:(int64_t)userId role:(IMUserRole)contactRole
{
    
//    [self.identityScope lock];
    
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    [self.dbHelper executeDB:^(FMDatabase *db) {
        // 采用内级联查询
        NSString *insTableName = [TeacherContacts getTableName];
        NSString *query = [NSString stringWithFormat:@"select USERS.rowid, USERS.userId, USERS.userRole, USERS.name, USERS.avatar, USERS.nameHeader, \
                           TEACHERCONTACTS.remarkName, TEACHERCONTACTS.remarkHeader \
                           TEACHERCONTACTS.blackStatus, TEACHERCONTACTS.originType, TEACHERCONTACTS.focusType \
                           TEACHERCONTACTS.tinyFoucs, TEACHERCONTACTS.focusTime,TEACHERCONTACTS.fansTime \
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
//    [self.identityScope unlock];
    return users;
}

- (TeacherContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner
{
    if (owner.userRole != eUserRole_Teacher) return nil;
    
    NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contactId, (long)contactRole];
    TeacherContacts *contact = (TeacherContacts *)[self.identityScope objectByKey:key lock:YES];
    
    if (! contact)
    {
        NSString *queryString = [NSString stringWithFormat:@"userId=%lld AND contactId=%lld AND contactRole=%ld", owner.userId, contactId, (long)contactRole];
        contact = [self.dbHelper searchSingle:[TeacherContacts class] where:queryString orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:queryString class:[TeacherContacts class]];
        
        if (contact)
        {
            [self attachEntityKey:key entity:contact lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:@"nil " class:[TeacherContacts class]];
    }
    
    return contact;
}

- (void)insertOrUpdateContact:(TeacherContacts *)contact owner:(User *)owner
{
    if ([self loadContactId:contact.contactId contactRole:contact.contactRole owner:owner] == nil)
    {
        [self.dbHelper insertToDB:contact];
        NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contact.contactId, (long)contact.contactRole];
        [self attachEntityKey:key entity:contact lock:YES];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"insert" class:[TeacherContacts class]];
    }
}

- (void)deleteAllContacts:(User *)owner
{
    if (owner.userRole != eUserRole_Teacher) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld", owner.userId];
    [self.dbHelper deleteWithClass:[TeacherContacts class] where:sql];
    
    [self.identityScope clear];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"deleteALl" class:[TeacherContacts class]];
}

- (void)deleteContactId:(int64_t)contactId contactRole:(IMUserRole)contactRole owner:(User *)owner
{
    if (owner.userRole != eUserRole_Teacher ) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld and contactId=%lld and contactRole=%ld", owner.userId, contactId, (long)contactRole];
    [self.dbHelper deleteWithClass:[TeacherContacts class] where:sql];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:@"delete" class:[TeacherContacts class]];
    
    NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", owner.userId, contactId, (long)contactRole];
    TeacherContacts *contact = [self.identityScope objectByKey:key lock:YES];
    
    if (contact)
    {
        [self detach:key];
    }
}

- (BOOL)isStanger:(User *)contact withOwner:(User *)owner
{
    TeacherContacts *teacher = [self loadContactId:contact.userId contactRole:contact.userRole owner:owner];
    if (teacher == nil) {
        return YES;
    }
    
    if ((teacher.focusType == eIMFocusType_None && teacher.tinyFoucs == eIMTinyFocus_None) ||
        (teacher.focusType == eIMFocusType_Passive && teacher.tinyFoucs == eIMTinyFocus_None)) {
        return YES;
    }
    return NO;
}
@end
