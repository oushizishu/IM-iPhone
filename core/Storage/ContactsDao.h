//
//  ContactsDao.h
//  Pods
//
//  Created by 杨磊 on 16/3/7.
//
//

#import "IMBaseDao.h"
#import "BJIMConstants.h"
#import "Contacts.h"

@class User;
@class Contacts;
@interface ContactsDao : IMBaseDao

- (NSArray<User *> *)loadAll:(User *)owner
                role:(IMUserRole)contactRole;

- (Contacts *)loadContactId:(int64_t)contactId
                       contactRole:(IMUserRole)contactRole
                             owner:(User *)owner;

- (void)insertOrUpdateContact:(User *)contact
                        owner:(User *)owner;

- (void)deleteAllContacts:(User *)owner;

- (void)deleteContactId:(int64_t)contactId
            contactRole:(IMUserRole)contactRole
                  owner:(User *)owner;

- (BOOL)hasContactOwner:(User *)owner
                contact:(User *)contact;

#pragma mark - 黑名单 api
- (void)addBlack:(User *)contact
           owner:(User *)owner;

- (void)removeBlack:(User *)contact
              owner:(User *)owner;

- (NSArray<User *> *)loadAllBlack:(User *)owner;

- (void)removeAllBlack:(User *)owner;
@end
