//
//  BJIMManager.h
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "IMMessage.h"
#import "User.h"
#import "Group.h"
#import "Conversation.h"
#import "IMEnvironment.h"

#import "BaseResponse.h"
#import "SocialContacts.h"
/**
 *  IM 管理类， 与上层交互
 */
@interface BJIMManager : NSObject

/**
 *  当前服务器环境标志变量
 */
@property (nonatomic, assign, setter=setDebugMode:) IMSERVER_ENVIRONMENT debugMode;

+ (instancetype)shareInstance;

#pragma mark - 登录退出 IM
/**
 *  登录 IM
 *
 *  @param userId     <#userId description#>
 *  @param userName   <#userName description#>
 *  @param userAvatar <#userAvatar description#>
 *  @param userRole   <#userRole description#>
 */
- (void)loginWithOauthToken:(NSString *)OauthToken
                     UserId:(int64_t)userId
                   userName:(NSString *)userName
                 userAvatar:(NSString *)userAvatar
                   userRole:(IMUserRole)userRole;

/**
 *  退出 IM
 */
- (void)logout;

#pragma mark - 会话 
- (NSArray *)getAllConversation;
- (Conversation *)getConversationUserId:(int64_t)userId role:(IMUserRole)userRole;
- (Conversation *)getConversationGroupId:(int64_t)groupId;
- (NSInteger)getAllConversationUnreadNum;
//删除会话
- (BOOL)deleteConversation:(Conversation *)conversation;

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message;
- (void)retryMessage:(IMMessage *)message;
//- (void)loadMoreMessages:(Conversation *)conversation;
// 初始化以及加载会话消息
- (void)loadMessageFromMinMsgId:(NSString *)minMsgId withUser:(User *)user; // 加载单聊会话消息
- (void)loadMessageFromMinMsgId:(NSString *)minMsgId withGroup:(Group *)group; // 加载群聊会话消息

- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole;
- (Group *)getGroup:(int64_t)groupId;

#pragma mark - current chat
//开始聊天
- (void)startChatToUserId:(int64_t)userId role:(IMUserRole)userRole;
- (void)startChatToGroup:(int64_t)groupId;
// 退出聊天
- (void)stopChat;

#pragma mark - 联系人
- (NSArray *)getMyGroups;
- (NSArray *)getMyTeacherContacts;
- (NSArray *)getMyStudentContacts;
- (NSArray *)getMyInstitutionContacts;

// 获取新粉丝列表
- (NSArray*)getMyNewFans;
// 我的粉丝列表
- (NSArray *)getMyFans;
// 我的关注列表
- (NSArray *)getMyAttentions;

- (void)setUser:(User *)user;

- (void)addRecentContactId:(int64_t)userId
               contactRole:(IMUserRole)userRole
                  callback:(void(^)(BaseResponse *response))callback;

//添加关注
- (void)addAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;
//取消关注
- (void)cancelAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;

//添加黑名单
- (void)addBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;
//取消黑名单
- (void)cancelBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;

#pragma mark - 备注名
- (void)setRemarkName:(NSString *)remarkName
                 user:(User *)user
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;


//- (void)setRemarkName:(NSString *)remarkName
//                group:(Group *)group
//             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

#pragma mark -系统小秘书 & 客服
//系统小秘书
- (User *)getSystemSecretary;
// 客服 
- (User *)getCustomWaiter;

#pragma mark - utils
// 判断该老师是否为我的老师（to学生端）
- (BOOL)isMyTeacher:(int64_t)teacherId;
- (BOOL)isMyInstitution:(int64_t)orgId;
- (BOOL)isMyGroup:(int64_t)groupId;
- (IMGroupMsgStatus)getGroupMsgStatus:(int64_t)groupId;

- (SocialContacts *)getSocialUser:(User *)user;

#pragma mark - 应用进入前后台
- (void)applicationDidEnterBackgroud;
- (void)applicationDidBecomeActive;

#pragma mark - add Delegates
- (void)addConversationChangedDelegate:(id<IMConversationChangedDelegate>)delegate;
- (void)addReceiveNewMessageDelegate:(id<IMReceiveNewMessageDelegate>)delegate;
- (void)addDeliveryMessageDelegate:(id<IMDeliveredMessageDelegate>)delegate;
- (void)addCmdMessageDelegate:(id<IMCmdMessageDelegate>)delegate;
- (void)addContactChangedDelegate:(id<IMContactsChangedDelegate>)delegate;
- (void)addLoadMoreMessagesDelegate:(id<IMLoadMessageDelegate>)delegate;
- (void)addRecentContactsDelegate:(id<IMRecentContactsDelegate>)delegate;
- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate;
- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate;
- (void)addDisconnectionDelegate:(id<IMDisconnectionDelegate>)delegate;
- (void)addLoginLogoutDelegate:(id<IMLoginLogoutDelegate>)delegate;
- (void)addUnReadNumChangedDelegate:(id<IMUnReadNumChangedDelegate>)delegate;

@end

@class GetGroupMemberModel;
@interface BJIMManager (GroupManager)
- (void)addGroupManagerDelegate:(id<IMGroupManagerResultDelegate>)delegate;
- (void)getGroupProfile:(int64_t)groupId;
- (void)leaveGroupWithGroupId:(int64_t)groupId;
- (void)disbandGroupWithGroupId:(int64_t)groupId;
- (void)getGroupMemberWithGroupId:(int64_t)groupId page:(NSUInteger)page;
- (void)getGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)page;
- (void)getGroupMemberWithModel:(GetGroupMemberModel *)model;
- (void)changeGroupName:(NSString *)name groupId:(int64_t)groupId;
- (void)setGroupMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId;
- (void)setGroupPushStatus:(IMGroupPushStatus)status groupid:(int64_t)groupId;
@end
