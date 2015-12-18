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

#import "GroupDetail.h"
#import <BJHL-Common-iOS-SDK/BJNetworkUtil.h>

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

//获取群组详情
- (void)getGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback;
//获取群成员
- (void)getGroupMembers:(int64_t)groupId page:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void(^)(NSError *error ,NSArray *members,BOOL hasMore,BOOL is_admin,BOOL is_major))callback;

//移交群
- (void)transferGroup:(int64_t)groupId
          transfer_id:(int64_t)transfer_id
        transfer_role:(int64_t)transfer_role
             callback:(void(^)(NSError *error))callback;

//设置群头像
- (void)setGroupAvatar:(int64_t)groupId
                avatar:(int64_t)avatar
              callback:(void(^)(NSError *error))callback;

//设置群头像与名称
- (void)setGroupNameAvatar:(int64_t)groupId
                 groupName:(NSString*)groupName
                    avatar:(int64_t)avatar
                  callback:(void(^)(NSError *error))callback;

//设置群管理
- (void)setGroupAdmin:(int64_t)groupId
          user_number:(int64_t)user_number
            user_role:(int64_t)user_role
               status:(int64_t)status
             callback:(void(^)(NSError *error))callback;

//移除群成员
- (void)removeGroupMember:(int64_t)groupId
              user_number:(int64_t)user_number
                user_role:(int64_t)user_role
                 callback:(void(^)(NSError *error))callback;

//退群
- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;

//解散群
- (void)postDisBandGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;

//获取群文件
- (void)getGroupFiles:(int64_t)groupId
         last_file_id:(int64_t)last_file_id
             callback:(void(^)(NSError *error ,NSArray<GroupFile *> *list))callback;
//上传文件
- (BJNetRequestOperation*)uploadGroupFile:(NSString*)attachment
                                 filePath:(NSString*)filePath
                                 fileName:(NSString*)fileName
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
                                 progress:(onProgress)progress;
//添加文件
- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback;

//文件下载
- (BJNetRequestOperation*)downloadGroupFile:(NSString*)fileUrl
                                   filePath:(NSString*)filePath
                                   callback:(void(^)(NSError *error))callback
                                   progress:(onProgress)progress;

//预览文件
- (void)previewGroupFile:(int64_t)groupId
                 file_id:(int64_t)file_id
                callback:(void(^)(NSError *error ,NSString *url))callback;

//新增设置群消息状态接口（与之前的接口有区别）
- (void)setGroupMsgStatus:(int64_t)status
                  groupId:(int64_t)groupId
                 callback:(void(^)(NSError *error))callback;

//删除群文件
- (void)deleteGroupFile:(int64_t)groupId
                file_id:(int64_t)file_id
               callback:(void(^)(NSError *error))callback;

//发布群公告
-(void)createGroupNotice:(int64_t)groupId
                 content:(NSString*)content
                callback:(void(^)(NSError *error))callback;

//浏览群公告
-(void)getGroupNotice:(int64_t)groupId
              last_id:(int64_t)last_id
            page_size:(int64_t)page_size
             callback:(void(^)(NSError *error ,BOOL isAdmin ,NSArray<GroupNotice*> *list ,BOOL hasMore))callback;

//删除群公告
-(void)removeGroupNotice:(int64_t)notice_id
                group_id:(int64_t)group_id
                callback:(void(^)(NSError *error))callback;

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
- (void)setUser:(User *)user;

- (void)addRecentContactId:(int64_t)userId
               contactRole:(IMUserRole)userRole
                  callback:(void(^)(BaseResponse *response))callback;

//添加关注
- (void)addAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result, User *user))callback;
//取消关注
- (void)cancelAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result, User *user))callback;

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


#pragma mark - 应用进入前后台
- (void)applicationDidEnterBackgroud;
- (void)applicationDidBecomeActive;

#pragma mark - add Delegates
- (void)addConversationChangedDelegate:(id<IMConversationChangedDelegate>)delegate;
- (void)addReceiveNewMessageDelegate:(id<IMReceiveNewMessageDelegate>)delegate;
- (void)addDeliveryMessageDelegate:(id<IMDeliveredMessageDelegate>)delegate;
- (void)addCmdMessageDelegate:(id<IMCmdMessageDelegate>)delegate;
- (void)addContactChangedDelegate:(id<IMContactsChangedDelegate>)delegate;
- (void)addNewGroupNoticeDelegate:(id<IMNewGRoupNoticeDelegate>)delegate;
- (void)addLoadMoreMessagesDelegate:(id<IMLoadMessageDelegate>)delegate;
- (void)addRecentContactsDelegate:(id<IMRecentContactsDelegate>)delegate;
- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate;
- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate;
- (void)addDisconnectionDelegate:(id<IMDisconnectionDelegate>)delegate;
- (void)addLoginLogoutDelegate:(id<IMLoginLogoutDelegate>)delegate;

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
