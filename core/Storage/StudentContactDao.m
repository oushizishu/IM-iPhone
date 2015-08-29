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
    
    NSString *query = [NSString stringWithFormat:@" userId=%lld and contactRole=%ld", userId, (long)contactRole];
    
    NSArray *array = [self.dbHelper search:[StudentContacts class] where:query orderBy:nil offset:0 count:0];
    
     NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        StudentContacts *item = (StudentContacts *)[array objectAtIndex:index];
        [self attachEntityKey:@(item.rowid) entity:item lock:NO];
        
        User *user = [self.imStroage.userDao loadUser:item.contactId role:item.contactRole];
        user.remarkName = item.remarkName;
        user.remarkHeader = item.remarkHeader;
        [users addObject:user];
    }
    
    [self.identityScope unlock];
    return users;
}

- (StudentContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner
{
    if (owner.userRole != eUserRole_Student) return nil;
    
    StudentContacts *contact = (StudentContacts *)[self.identityScope objectByCondition:^BOOL(id key, id item) {
        StudentContacts *_contact = (StudentContacts *)item;
        return (_contact.contactId == contactId && _contact.contactRole == contactRole && _contact.userId == owner.userId);
    } lock:YES];
    
    if (! contact)
    {
        NSString *queryString = [NSString stringWithFormat:@"userId=%lld AND contactId=%lld AND contactRole=%ld", owner.userId, contactId, (long)contactRole];
        contact = [self.dbHelper searchSingle:[StudentContacts class] where:queryString orderBy:nil];
        if (contact)
        {
            [self attachEntityKey:@(contact.rowid) entity:contact lock:YES];
        }
    }
    
    return contact;
}

- (void)insertOrUpdateContact:(StudentContacts *)contact owner:(User *)owner
{
    if ([self loadContactId:contact.contactId contactRole:contact.contactRole owner:owner] == nil)
    {
        [self.dbHelper insertToDB:contact];
        [self attachEntityKey:@(contact.rowid) entity:contact lock:YES];
    }
}

- (void)deleteAllContacts:(User *)owner
{
    if (owner.userRole != eUserRole_Student) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld", owner.userId];
    [self.dbHelper deleteWithClass:[StudentContacts class] where:sql];
    
    [self.identityScope clear];
}

- (void)deleteContactId:(int64_t)contactId contactRole:(IMUserRole)contactRole owner:(User *)owner
{
    if (owner.userRole != eUserRole_Student ) return;
    NSString *sql = [NSString stringWithFormat:@"userId=%lld and contactId=%lld and contactRole=%ld", owner.userId, contactId, (long)contactRole];
    [self.dbHelper deleteWithClass:[StudentContacts class] where:sql];
    
    StudentContacts *contact = [self.identityScope objectByCondition:^BOOL(id key, id item) {
        StudentContacts *_contact = (StudentContacts *)item;
        return (_contact.contactId == contactId && _contact.contactRole == contactRole && _contact.userId == owner.userId);
    } lock:YES];
    
    if (contact)
    {
        [self detach:@(contact.rowid)];
    }
}
@end