//
//  BJIMStorage.h
//  Pods
//
//  Created by 杨磊 on 15/5/14.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "UserDao.h"
#import "InstitutionContactDao.h"
#import "StudentContactDao.h"
#import "TeacherContactDao.h"
#import "GroupDao.h"
#import "GroupMemberDao.h"
#import "IMMessageDao.h"
#import "ConversationDao.h"
#import "FreshFansContactDao.h"
#import "SocialContactsDao.h"

@class BJIMConversationDBManager;
@class User;
@class Group;
@class IMMessage;
@class Conversation;
@class GroupMember;
@class RecentContacts;
@interface BJIMStorage : NSObject

@property (nonatomic, strong) UserDao *userDao;
@property (nonatomic, strong) InstitutionContactDao *institutionDao;
@property (nonatomic, strong) StudentContactDao *studentDao;
@property (nonatomic, strong) TeacherContactDao *teacherDao;
@property (nonatomic, strong) GroupDao *groupDao;
@property (nonatomic, strong) GroupMemberDao *groupMemberDao;
@property (nonatomic, strong) IMMessageDao *messageDao;
@property (nonatomic, strong) ConversationDao *conversationDao;
@property (nonatomic, strong) FreshFansContactDao *nFansContactDao;
@property (nonatomic, strong) SocialContactsDao *socialContactsDao;
@property (nonatomic, strong) LKDBHelper *dbHelper;

//clear DB cache
- (void)clearSession;

//conversation
- (long)sumOfAllConversationUnReadNumOwnerId:(int64_t)ownerId userRole:(IMUserRole)userRole;

//contact
- (BOOL)hasContactOwner:(User *)owner contact:(User *)contact;
- (void)insertOrUpdateContactOwner:(User *)owner contact:(User *)contact;
- (void)deleteMyContactWithUser:(User *)user;

- (NSArray *)queryRecentContactsWithUserId:(int64_t)userId userRole:(IMUserRole)userRole;

//other
- (BOOL)checkMessageStatus;

// bugfix
// msgId 长度小于 11
- (NSArray *)queryAllBugMessages;
- (void)updateConversationWithErrorLastMessageId:(NSString *)errMsgId newMsgId:(NSString *)msgId;
- (void)updateGroupErrorMsgId:(NSString *)errMsgId newMsgId:(NSString *)msgId;

/**
 *  生成一个假的 msgId
 * PS：基于当前表的最大 msgId + 0.001
 *
 *  @return <#return value description#>
 */
- (NSString *)nextFakeMessageId;
@end
