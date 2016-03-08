//
//  StudentContactDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "IMBaseDao.h"
#import "StudentContacts.h"

/**
 *  4.1 版本之后被废弃。 使用 {@link ContactsDao}
 */
@interface StudentContactDao : IMBaseDao
- (NSArray *)loadAll:(int64_t)userId role:(IMUserRole)contactRole;


- (StudentContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner;

- (void)insertOrUpdateContact:(StudentContacts *)contact owner:(User *)owner;

- (void)deleteAllContacts:(User *)owner;

- (void)deleteContactId:(int64_t)contactId
            contactRole:(IMUserRole)contactRole
                  owner:(User *)owner;
@end
