//
//  StudentContactDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "IMBaseDao.h"
#import "StudentContacts.h"

@interface StudentContactDao : IMBaseDao
- (NSArray *)loadAll:(int64_t)userId role:(IMUserRole)contactRole;
//我的关注
- (NSArray *)loadMyAttentions:(int64_t)userId role:(IMUserRole)contactRole;
//我的粉丝
- (NSArray *)loadMyFans:(int64_t)userId role:(IMUserRole)contactRole;
//我的黑名单
- (NSArray *)loadMyBlackList:(int64_t)userId role:(IMUserRole)contactRole;



- (StudentContacts *)loadContactId:(int64_t)contactId
                           contactRole:(IMUserRole)contactRole
                                 owner:(User *)owner;

- (void)insertOrUpdateContact:(StudentContacts *)contact owner:(User *)owner;

- (void)deleteAllContacts:(User *)owner;

- (void)deleteContactId:(int64_t)contactId
            contactRole:(IMUserRole)contactRole
                  owner:(User *)owner;

- (BOOL)isStanger:(User *)contact withOwner:(User *)owner;
@end
