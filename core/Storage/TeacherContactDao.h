//
//  TeacherContactDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "IMBaseDao.h"
#import "TeacherContacts.h"

/**
 *  4.1 版本之后被废弃。 使用 {@link ContactsDao}
 */
@interface TeacherContactDao : IMBaseDao
- (NSArray *)loadAll:(int64_t)userId role:(IMUserRole)contactRole;

- (TeacherContacts *)loadContactId:(int64_t)contactId
                       contactRole:(IMUserRole)contactRole
                             owner:(User *)owner;

- (void)insertOrUpdateContact:(TeacherContacts *)contact owner:(User *)owner;

- (void)deleteAllContacts:(User *)owner;

- (void)deleteContactId:(int64_t)contactId
            contactRole:(IMUserRole)contactRole
                  owner:(User *)owner;

@end
