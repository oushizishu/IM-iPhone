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
//删除会话
- (BOOL)deleteConversation:(Conversation *)conversation;

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message;
- (void)retryMessage:(IMMessage *)message;
//- (void)loadMoreMessages:(Conversation *)conversation;
// 初始化以及加载会话消息
- (void)loadMessageFromMinMsgId:(double_t)minMsgId inConversation:(Conversation *)conversation;

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
//在回调事件中取值
- (void)getMyRecentContacts;

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

@end
