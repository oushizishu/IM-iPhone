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
//获取关注关系
- (IMFocusType)getAttentionState:(User *)contact withOwner:(User *)owner;
//获取浅关注状态
- (IMTinyFocus)getTinyFoucsState:(User *)contact withOwner:(User *)owner;

//设置浅关注状态
- (void)setContactTinyFoucs:(IMTinyFocus)type contact:(User*)contact owner:(User *)owner;
//设置关注关系
- (void)setContactFocusType:(BOOL)opType contact:(User*)contact owner:(User *)owner;

@end
