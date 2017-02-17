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
#import "AutoResponseList.h"
#import <BJHL-Network-iOS/BJHL-Network-iOS.h>

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
//获取所有消息会话(系统消息)
- (NSArray *)getAllConversation;
//获取会话
- (Conversation *)getConversationUserId:(int64_t)userId role:(IMUserRole)userRole;
//获取群组
- (Conversation *)getConversationGroupId:(int64_t)groupId;
//未读消息总数
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
- (void)getUserOnlineStatus:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(IMUserOnlineStatus onlineStatus))callback;

- (void)resetAllUnReadNum;

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
- (void)refreshAllContacts;

//清空用户所有会话及消息
- (void)clearConversationAndMessage;

- (void)setUser:(User *)user;

- (void)addRecentContactId:(int64_t)userId
               contactRole:(IMUserRole)userRole
                  callback:(void(^)(BaseResponse *response))callback __deprecated_msg("已过期");

#pragma mark - 关系操作，拉黑
- (void)addBlackContactId:(int64_t)userId
              contactRole:(IMUserRole)userRole
                 callback:(void(^)(BaseResponse *response))callback;

- (void)removeBlackContactId:(int64_t)userId
                 contactRole:(IMUserRole)userRole
                    callback:(void(^)(BaseResponse *reponse))callback;

- (void)getBlackList:(void(^)(NSArray<User *> *blacklist))callback;


#pragma mark - 备注名
- (void)setRemarkName:(NSString *)remarkName
                 user:(User *)user
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

#pragma mark - autoresponse
- (void)addAutoResponseWithContent:(NSString *)content
                           success:(void(^)(NSInteger contentId))succss
                           failure:(void(^)(NSError *error))failure;

- (void)editAutoResponseWithContent:(NSString *)content
                          contentId:(NSInteger)contentId
                            success:(void(^)(NSInteger contentId))succss
                            failure:(void(^)(NSError *error))failure;

- (void)setEnableAutoResponseWithEnable:(BOOL)enable
                                success:(void(^)())succss
                                failure:(void(^)(NSError *error))failure;

- (void)setSelectedAutoResponseWithContentId:(NSInteger)contentId
                                     success:(void(^)())succss
                                     failure:(void(^)(NSError *error))failure;

- (void)delAutoResponseWithContentId:(NSInteger)contentId
                             success:(void(^)())succss
                             failure:(void(^)(NSError *error))failure;

- (void)getAllAutoResponseWithSuccess:(void(^)(AutoResponseList *result))succss
                              failure:(void(^)(NSError *error))failure;


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
- (void)addRecentContactsDelegate:(id<IMRecentContactsDelegate>)delegate __deprecated_msg("已过期");
- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate;
- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate;
- (void)addDisconnectionDelegate:(id<IMDisconnectionDelegate>)delegate;
- (void)addLoginLogoutDelegate:(id<IMLoginLogoutDelegate>)delegate;
- (void)addUnReadNumChangedDelegate:(id<IMUnReadNumChangedDelegate>)delegate;
- (void)addUserAvatarInvalidDelegate:(id<IMUserAvatarInvalidDelegate>)delegate;
@end

@class GetGroupMemberModel;
@class SearchMember;

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

- (IMGroupMsgStatus)getGroupMsgStatus:(int64_t)groupId;

//获取群组详情
- (void)getGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback;
//获取群成员
- (void)getGroupMembers:(int64_t)groupId page:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void(^)(NSError *error ,NSArray *members,BOOL hasMore,BOOL is_admin,BOOL is_major))callback;

//判断当前用户在本群的角色
- (void)isAdmin:(int64_t)groupId callback:(void(^)(NSError *error, IMGroupMemberRole groupMemberRole))callback;

//群成员搜索
- (void)getSearchMemberList:(int64_t)groupId query:(NSString *)query callback:(void(^)(NSError *error, NSArray<SearchMember *> *memberList))callback;

//群用户禁言/解除禁言  status: 1:设置在该群中禁言  0:取消禁言
- (void)setGroupMemberForbid:(int64_t)groupId
                 user_number:(int64_t)user_number
                   user_role:(int64_t)user_role
                      status:(int64_t)status
                    callback:(void(^)(NSError *error))callback;


// 判断owner 与 contact 是否为联系人
- (BOOL)hasContactOwner:(User *)owner
                contact:(User *)contact;

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
- (BJCNNetRequestOperation*)uploadGroupFile:(NSString*)attachment
                                 filePath:(NSString*)filePath
                                 fileName:(NSString*)fileName
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
                                 progress:(BJCNOnProgress)progress;

//上传图片文件
- (BJCNNetRequestOperation*)uploadImageFile:(NSString*)fileName
                                 filePath:(NSString*)filePath
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback;

//添加文件
- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback;

//文件下载
- (BJCNNetRequestOperation*)downloadGroupFile:(NSString*)fileUrl
                                   filePath:(NSString*)filePath
                                   callback:(void(^)(NSError *error))callback
                                   progress:(BJCNOnProgress)progress;

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

@end
