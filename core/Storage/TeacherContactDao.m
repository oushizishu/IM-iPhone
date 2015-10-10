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
    
    [self.identityScope lock];
    
    NSString *query = [NSString stringWithFormat:@" userId=%lld and contactRole=%ld", userId, (long)contactRole];
    
    NSArray *array = [self.dbHelper search:[TeacherContacts class] where:query orderBy:nil offset:0 count:0];
    
    [[DaoStatistics sharedInstance] logDBOperationSQL:query class:[TeacherContacts class]];
    
    NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        TeacherContacts *item = (TeacherContacts *)[array objectAtIndex:index];
        
        NSString *key = [NSString stringWithFormat:@"%lld-%lld-%ld", userId, item.contactId, (long)contactRole];
        
        [self attachEntityKey:key entity:item lock:NO];
        
        User *user = [self.imStroage.userDao loadUser:item.contactId role:item.contactRole];
        user.remarkName = item.remarkName;
        user.remarkHeader = item.remarkHeader;
        [users addObject:user];
    }
    
    [self.identityScope unlock];
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
        [self detach:@(contact.rowid)];
    }
}
@end
