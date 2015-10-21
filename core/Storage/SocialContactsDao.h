//
//  SocialContactsDao.h
//  Pods
//
//  Created by 杨磊 on 15/10/21.
//
//

#import "IMBaseDao.h"
#import "SocialContacts.h"
#import "User.h"

@interface SocialContactsDao : IMBaseDao

- (SocialContacts *)loadContactId:(int64_t)contactId
                      contactRole:(IMUserRole)contactRole
                          ownerId:(int64_t)ownerId
                        ownerRole:(IMUserRole)ownerRole;

/**
 *  判断陌生人
 *
 *  @param contact <#contact description#>
 *  @param owner   <#owner description#>
 *
 *  @return <#return value description#>
 */
- (BOOL)isStanger:(User *)contact withOwner:(User *)owner;

//获取关注关系
- (IMFocusType)getAttentionState:(User *)contact withOwner:(User *)owner;
//获取浅关注状态
- (IMTinyFocus)getTinyFoucsState:(User *)contact withOwner:(User *)owner;

//设置浅关注状态
- (void)setContactTinyFoucs:(IMTinyFocus)type contact:(User*)contact owner:(User *)owner;
//设置关注关系
- (void)setContactFocusType:(BOOL)opType contact:(User*)contact owner:(User *)owner;

//我的关注
- (NSArray *)loadAllAttentions:(User *)owner;
//我的粉丝
- (NSArray *)loadAllFans:(User *)owner;
//我的黑名单
- (NSArray *)loadAllBlacks:(User *)owner;

/**
 *  我关注的学生、老师、机构
 *
 *  @param owner <#owner description#>
 *
 *  @return <#return value description#>
 */
- (NSArray *)loadAllAttentionsStudent:(User *)owner;
- (NSArray *)loadAllAttentionsTeacher:(User *)owner;
- (NSArray *)loadAllAttentionsInstitution:(User *)owner;

- (void)insert:(User *)user withOwner:(User *)owner;
- (void)clearAll:(User *)owner;

@end
