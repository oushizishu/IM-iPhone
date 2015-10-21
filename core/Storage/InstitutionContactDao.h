//
//  InstitutionContactDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "IMBaseDao.h"
#import "InstitutionContacts.h"

@interface InstitutionContactDao : IMBaseDao
- (NSArray *)loadAll:(int64_t)userId role:(IMUserRole)contactRole;

- (InstitutionContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner;

- (void)insertOrUpdateContact:(InstitutionContacts *)contact owner:(User *)owner;

- (void)deleteAllContacts:(User *)owner;

- (void)deleteContactId:(int64_t)contactId
            contactRole:(IMUserRole)contactRole
                  owner:(User *)owner;

@end
