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

//判断陌生人
- (BOOL)isStanger:(User *)contact withOwner:(User *)owner;
//判断是否关注对方
- (BOOL)isAttention:(User *)contact withOwner:(User *)owner;
//判断是否被对方关注
- (BOOL)isBeAttention:(User *)contact withOwner:(User *)owner;
//设置浅关注状态
- (void)setContactTinyFoucs:(BOOL)opType userID:(int64_t)userId role:(IMUserRole)contactRole owner:(User *)owner;
//设置黑名单状态
- (void)setContactFocusType:(BOOL)opType userID:(int64_t)userId role:(IMUserRole)contactRole owner:(User *)owner;

@end
