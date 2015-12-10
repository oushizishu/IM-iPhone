//
//  BJIMService.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "BJIMStorage.h"
#import "IMMessage.h"
#import "BJIMAbstractEngine.h"
#import "GroupDetail.h"
#import <BJHL-Common-iOS-SDK/BJNetworkUtil.h>


@class BaseResponse;
@class IMBaseOperation;
@interface BJIMService : NSObject
@property (nonatomic, assign) BOOL bIsServiceActive;
@property (nonatomic, strong, readonly) BJIMAbstractEngine *imEngine;
@property (nonatomic, strong, readonly) BJIMStorage *imStorage;

@property (nonatomic, strong, readonly) NSOperationQueue *writeOperationQueue; // DB 写操作线程

- (void)startServiceWithOwner:(User *)owner;

- (void)stopService;

//- (void)removeOperationsWhileStopChat;

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message;
- (void)retryMessage:(IMMessage *)message;
- (void)loadMessagesUser:(User *)user orGroup:(Group *)group minMsgId:(NSString *)minMsgId;

#pragma mark - getter 
- (NSArray *)getAllConversationWithOwner:(User *)owner;
- (Conversation *)getConversationUserOrGroupId:(int64_t)userOrGroupId
                                      userRole:(IMUserRole)userRole
                                         ownerId:(int64_t)ownerId
                                     ownerRole:(IMUserRole)ownerRole
                                        chat_t:(IMChatType)chat_t;
- (void)insertConversation:(Conversation *)conversation;
- (void)resetConversationUnreadnum:(Conversation *)conversation;
- (NSInteger)getAllConversationUnReadNumWithUser:(User *)owner;
- (BOOL)deleteConversation:(Conversation *)conversation owner:(User *)owner;

- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole;
- (void)setUser:(User *)user;
- (Group *)getGroup:(int64_t)groupId;

- (void)getGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback;

- (void)getGroupMembers:(int64_t)groupId page:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void(^)(NSError *error ,NSArray *members,BOOL hasMore))callback;

- (void)getGroupFiles:(int64_t)groupId
         last_file_id:(int64_t)last_file_id
             callback:(void(^)(NSError *error ,NSArray<GroupFile *> *list))callback;

- (NSOperation*)uploadGroupFile:(NSString*)attachment
                       filePath:(NSString*)filePath
                       fileName:(NSString*)fileName
                       callback:(void(^)(NSError *error ,int64_t storage_id))callback
                       progress:(onProgress)progress;

- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback;

- (NSOperation*)downloadGroupFile:(NSString*)fileUrl
                         filePath:(NSString*)filePath
                         callback:(void(^)(NSError *error))callback
                         progress:(onProgress)progress;

- (NSArray *)getGroupsWithUser:(User *)user;
- (NSArray *)getTeacherContactsWithUser:(User *)user;
- (NSArray *)getStudentContactsWithUser:(User *)user;
- (NSArray *)getInstitutionContactsWithUser:(User *)user;

- (void)addRecentContactId:(int64_t)userId
               contactRole:(IMUserRole)userRole
                  callback:(void(^)(BaseResponse *response))callback;

#pragma mark -系统小秘书 & 客服
//系统小秘书
- (User *)getSystemSecretary;
// 客服
- (User *)getCustomWaiter;

// 获取陌生人(返回用户对象,陌生人对象是抽象出来的用户)
- (User*)getStranger;
// 获取陌生人会话(返回会话对象，针对上面陌生人对象，抽象用户的会话)
//- (Conversation *)getStrangerConversation;
// 获取陌生人会话列表(返回会话对象列表，针对具体用户对象的会话,不是所有陌生人会话，是已建立的陌生人会话。)
- (NSArray *)getMyStrangerConversations;
// 清除陌生人会话的未读消息数为0
- (void)clearStangerConversationUnreadCount;
// 获取陌生人未读会话数
- (NSInteger)getMyStrangerConversationsCountHaveNoRead;

// 获取新粉丝(返回用户对象,新粉丝对象是抽象出来的用户)
- (User *)getFreshFans;
//获取新粉丝会话(返回会话对象)
//- (Conversation *)getFreshFansConversation;
// 获取新粉丝列表(返回用户对象列表)
- (NSArray*)getMyFreshFans;
// 清空新粉丝列表
- (void)clearMyFreshFans;
// 获取新粉丝数
- (NSInteger)getMyFreshFansCount;

// 我的互相关注列表
- (NSArray *)getMyMutualUsers;
// 我的互相关注人数
- (NSInteger)getMyMutualUsersCount;

// 我的粉丝列表(返回用户对象列表)
- (NSArray *)getMyFans;
// 我的粉丝数
- (NSInteger)getMyFansCount;
// 关注我的老师
- (NSArray *)getMyFansBelongToTeacher;
// 关注我的老师数
- (NSInteger)getMyFansBelongToTeacherCount;
// 关注我的学生
- (NSArray *)getMyFansBelongToStudent;
// 关注我的学生数
- (NSInteger)getMyFansBelongToStudentCount;
// 关注我的机构
- (NSArray *)getMyFansBelongToInstitution;
// 关注我的机构数
- (NSInteger)getMyFansBelongToInstitutionCount;


// 我的关注列表(返回用户对象列表)
- (NSArray *)getMyAttentions;
// 我的关注人数
- (NSInteger)getMyAttentionsCount;
// 我的关注老师列表
- (NSArray *)getMyAttentionsBelongToTeacher;
// 我关注的老师人数
- (NSInteger)getMyAttentionsBelongToTeacherCount;
// 我的关注同学列表
- (NSArray *)getMyAttentionsBelongToStudent;
// 我关注的同学人数
- (NSInteger)getMyAttentionsBelongToStudentCount;
// 我的关注机构列表
- (NSArray *)getMyAttentionsBelongToInstitution;
// 我关注的机构数
- (NSInteger)getMyAttentionsBelongToInstitutionCount;

// 我的黑名单列表
- (NSArray *)getMyBlackList;

/*
 判断陌生人关系,判断formUser是否是toUser的陌生人.
 参数user对象角色必须是老师，学生机构，且两个参数中，必须有一个是owner。才能进行判断，否则返回no。
 */
- (BOOL)getIsStanger:(User*)fromUser withUser:(User*)toUser;

//添加关注
- (void)addAttention:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result, User *user))callback;
//取消关注
- (void)cancelAttention:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result, User *user))callback;

//添加黑名单
- (void)addBlacklist:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback;
//取消黑名单
- (void)cancelBlacklist:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback;

#pragma mark - remark name
- (void)setRemarkName:(NSString *)remarkName
                 user:(User *)user
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

- (void)setRemarkName:(NSString *)remarkName
                group:(Group *)group
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

// 判断该老师是否为我的老师：(to学生端)
- (BOOL)hasTeacher:(int64_t)teacherId ofUser:(User *)user;
// 判断该机构是否为我的机构:(to学生端)
- (BOOL)hasInsitituion:(int64_t)institutionId ofUser:(User *)user;
- (GroupMember *)getGroupMember:(int64_t)groupId ofUser:(User *)user;
- (SocialContacts *)getSocialUser:(User *)user owner:(User *)owner;

- (void)applicationEnterBackground;
- (void)applicationEnterForeground;

- (void)appendOperationAfterContacts:(IMBaseOperation *)operation;

#pragma mark - add Delegates
- (void)addConversationChangedDelegate:(id<IMConversationChangedDelegate>)delegate;
- (void)notifyConversationChanged;

- (void)addReceiveNewMessageDelegate:(id<IMReceiveNewMessageDelegate>)delegate;
- (void)notifyReceiveNewMessages:(NSArray *)newMessages;

- (void)addDeliveryMessageDelegate:(id<IMDeliveredMessageDelegate>)delegate;
- (void)notifyDeliverMessage:(IMMessage *)message errorCode:(NSInteger)errorCode error:(NSString *)errorMsg;

- (void)addCmdMessageDelegate:(id<IMCmdMessageDelegate>)delegate;
- (void)notifyCmdMessages:(NSArray *)cmdMessages;

- (void)addContactChangedDelegate:(id<IMContactsChangedDelegate>)delegate;
- (void)notifyContactChanged;

- (void)addLoadMoreMessagesDelegate:(id<IMLoadMessageDelegate>)delegate;
- (void)notifyPreLoadMessages:(NSArray *)messages conversation:(Conversation *)conversation;
- (void)notifyLoadMoreMessages:(NSArray *)messages conversation:(Conversation *)conversation hasMore:(BOOL)hasMore;

- (void)addRecentContactsDelegate:(id<IMRecentContactsDelegate>)delegate;
- (void)notifyRecentContactsChanged:(NSArray *)contacts;

- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate;
- (void)notifyUserInfoChanged:(User *)user;

- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate;
- (void)notifyGroupProfileChanged:(Group *)group;

- (void)addDisconnectionDelegate:(id<IMDisconnectionDelegate>)delegate;

- (void)addLoginLogoutDelegate:(id<IMLoginLogoutDelegate>)delegate;
- (void)notifyIMLoginFinish;
- (void)notifyIMLogoutFinish;

- (void)addUnReadNumChangedDelegate:(id<IMUnReadNumChangedDelegate>)delegate;
- (void)notifyUnReadNumChanged:(NSInteger)unReadNum other:(NSInteger)otherNum;

@end
