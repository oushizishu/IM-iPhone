//
//  BJIMAbstractEngine.h
//  Pods
//
//  Created by 杨磊 on 15/9/8.
//
//

#import <Foundation/Foundation.h>
#import "SyncConfigModel.h"
#import "SendMsgModel.h"
#import "PollingResultModel.h"
#import "MyContactsModel.h"
#import "PostAchiveModel.h"
#import "SyncConfigModel.h"
#import "GetGroupMemberModel.h"
#import "BaseResponse.h"
#import "GroupDetail.h"
#import "IMUserOnlieStatusResult.h"
#import "SearchMemberList.h"
#import <BJHL-Network-iOS/BJHL-Network-iOS.h>

typedef NS_ENUM(NSInteger, IMNetworkEfficiency)
{
    IMNetwork_Efficiency_NONE = 0,  // 不可用
    IMNetwork_Efficiency_High = 1, // 高网络效率
    IMNetwork_Efficiency_Normal = 2,
    IMNetwork_Efficiency_Low = 3
};

@class BJIMAbstractEngine;
@protocol IMEngineNetworkEfficiencyDelegate <NSObject>

- (void)networkEfficiencyChanged:(IMNetworkEfficiency)efficiency engine:(BJIMAbstractEngine *)engine;

@end

@protocol IMEnginePostMessageDelegate <NSObject>

- (void)onPostMessageSucc:(IMMessage *)message result:(SendMsgModel *)model;
- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error;
- (void)onPostMessageAchiveSucc:(IMMessage *)message result:(PostAchiveModel *)model;

@end

@protocol IMEngineSynContactDelegate <NSObject>

- (void)didSyncContacts:(MyContactsModel *)model;

@end

@protocol IMEnginePollingDelegate <NSObject>

- (void)onShouldStartPolling;

- (void)onPollingFinish:(PollingResultModel *)model;

@end

@protocol  IMEngineGetMessageDelegate <NSObject>

- (void)onGetMsgSuccMinMsgId:(NSString *)minMsgId userId:(int64_t)userId userRole:(IMUserRole)userRole groupId:(int64_t)groupId result:(PollingResultModel *)model isFirstGetMsg:(BOOL)isFirstGetMsg;
- (void)onGetMsgFailMinMsgId:(NSString *)minMsgId userId:(int64_t)userId userRole:(IMUserRole)userRole groupId:(int64_t)groupId isFirstGetMsg:(BOOL)isFirstGetMsg;

@end

@protocol IMEngineSyncConfigDelegate <NSObject>

- (void)onSyncConfig:(SyncConfigModel *)model;

@end

typedef void(^errCodeFilterCallback)(IMErrorType errorCode, NSString *errMsg);

@interface BJIMAbstractEngine : NSObject

@property (nonatomic, assign, getter=isEngineActive) BOOL engineActive;
@property (nonatomic, weak) id<IMEnginePostMessageDelegate> postMessageDelegate;
@property (nonatomic, weak) id<IMEnginePollingDelegate> pollingDelegate;
@property (nonatomic, weak) id<IMEngineSynContactDelegate> synContactDelegate;
@property (nonatomic, weak) id<IMEngineGetMessageDelegate> getMsgDelegate;
@property (nonatomic, weak) id<IMEngineSyncConfigDelegate> syncConfigDelegate;


@property (nonatomic, weak) id<IMEngineNetworkEfficiencyDelegate> networkEfficiencyDelegate;

@property (nonatomic, copy) errCodeFilterCallback errCodeFilterCallback;


- (void)start;

- (void)stop;


- (void)syncConfig;
- (void)syncContacts;

/**
 *  发送消息
 *
 *  @param message <#message description#>
 */
- (void)postMessage:(IMMessage *)message;

- (void)postMessageAchive:(IMMessage *)message;

/**
 *  拉去消息
 *
 *  @param max_user_msg_id    <#max_user_msg_id description#>
 *  @param excludeUserMsgs    <#excludeUserMsgs description#>
 *  @param group_last_msg_ids <#group_last_msg_ids description#>
 *  @param groupId            <#groupId description#>
 */
- (void)postPullRequest:(int64_t)max_user_msg_id
           excludeUserMsgs:(NSString *)excludeUserMsgs
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId;

/**
 @deprecate
 *  获取更多消息，主要在群聊中
 *
 *  @param conversationId <#conversationId description#>
 *  @param eid            <#eid description#>
 *  @param groupId        <#groupId description#>
 *  @param userId         <#userId description#>
 *  @param excludeIds     <#excludeIds description#>
 *  @param startMessageId <#startMessageId description#>
 */
//- (void)getMsgConversation:(NSInteger)conversationId
//                  minMsgId:(NSString *)eid
//                   groupId:(int64_t)groupId
//                    userId:(int64_t)userId
//                excludeIds:(NSString *)excludeIds
//            startMessageId:(NSString *)startMessageId;

/**
 *  getMsg 方法
 *
 *  @param lastMessageId 当前需要获取的最大msgId
 *  @param groupId       <#groupId description#>
 *  @param userId        <#userId description#>
 *  @param userRole      <#userRole description#>
 *  @param excludeIds    <#excludeIds description#>
 */
- (void)postGetMsgLastMsgId:(NSString *)lastMessageId
                    groupId:(int64_t)groupId
                     userId:(int64_t)userId
                   userRole:(IMUserRole)userRole
                 excludeIds:(NSString *)excludeIds
              isFirstGetMsg:(BOOL)isFirstGetMsg;

- (void)postChangeRemarkName:(NSString *)remarkName
                      userId:(int64_t)userId
                    userRole:(IMUserRole)userRole
                    callback:(void(^)(NSString *remarkName, NSString *remarkHeader, NSInteger errCode, NSString *errMsg))callback;

- (void)postGetUserInfo:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(User *result))callback;

- (void)postGetGroupProfile:(int64_t)groupId callback:(void(^)(Group *result))callback;

- (void)getGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback;

- (void)getGroupMembers:(int64_t)groupId page:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void(^)(NSError *error ,NSArray *members,BOOL hasMore,BOOL is_admin,BOOL is_major))callback;

- (void)isAdmin:(int64_t)groupId callback:(void(^)(NSError *error, BOOL isAdmin))callback;

- (void)getSearchMemberList:(int64_t)groupId query:(NSString *)query callback:(void(^)(NSError *error, NSArray<SearchMember *> *memberList))callback;

- (void)setGroupMemberForbid:(int64_t)groupId
                 user_number:(int64_t)user_number
                   user_role:(int64_t)user_role
                      status:(int64_t)status
                    callback:(void(^)(NSError *error))callback;

- (void)postGetUserOnLineStatus:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(IMUserOnlieStatusResult *result))callback;

- (void)transferGroup:(int64_t)groupId
          transfer_id:(int64_t)transfer_id
        transfer_role:(int64_t)transfer_role
             callback:(void(^)(NSError *error))callback;

- (void)setGroupAvatar:(int64_t)groupId
                avatar:(int64_t)avatar
              callback:(void(^)(NSError *error))callback;

- (void)setGroupNameAvatar:(int64_t)groupId
                 groupName:(NSString*)groupName
                    avatar:(int64_t)avatar
                  callback:(void(^)(NSError *error))callback;

- (void)setGroupAdmin:(int64_t)groupId
          user_number:(int64_t)user_number
            user_role:(int64_t)user_role
               status:(int64_t)status
             callback:(void(^)(NSError *error))callback;

- (void)removeGroupMember:(int64_t)groupId
              user_number:(int64_t)user_number
                user_role:(int64_t)user_role
                 callback:(void(^)(NSError *error))callback;

- (void)getGroupFiles:(int64_t)groupId
         last_file_id:(int64_t)last_file_id
             callback:(void(^)(NSError *error ,NSArray<GroupFile *> *list))callback;

- (void)uploadGroupFile:(NSString*)attachment
                                 filePath:(NSString*)filePath
                                 fileName:(NSString*)fileName
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
                                 progress:(BJCNOnProgress)progress;

- (void)uploadImageFile:(NSString*)fileName
                                 filePath:(NSString*)filePath
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback;

- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback;

- (void)downloadGroupFile:(NSString*)fileUrl
                                   filePath:(NSString*)filePath
                                   callback:(void(^)(NSError *error))callback
                                   progress:(BJCNOnProgress)progress;

- (void)previewGroupFile:(int64_t)groupId
                 file_id:(int64_t)file_id
                callback:(void(^)(NSError *error ,NSString *url))callback;

- (void)setGroupMsgStatus:(int64_t)status
                  groupId:(int64_t)groupId
                 callback:(void(^)(NSError *error))callback;

- (void)deleteGroupFile:(int64_t)groupId
                file_id:(int64_t)file_id
               callback:(void(^)(NSError *error))callback;

-(void)createGroupNotice:(int64_t)groupId
                 content:(NSString*)content
                callback:(void(^)(NSError *error))callback;

-(void)getGroupNotice:(int64_t)groupId
              last_id:(int64_t)last_id
            page_size:(int64_t)page_size
             callback:(void(^)(NSError *error ,BOOL isAdmin ,NSArray<GroupNotice*> *list ,BOOL hasMore))callback;

-(void)removeGroupNotice:(int64_t)notice_id
                group_id:(int64_t)group_id
                callback:(void(^)(NSError *error))callback;

//添加黑名单
- (void)postAddBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;
//取消黑名单
- (void)postCancelBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;

#pragma mark - group
- (void)postGetGroupMembersWithModel:(GetGroupMemberModel *)model callback:(void (^)(GroupMemberListData *members, NSError *err))callback;
- (void)postGetGroupMembers:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index callback:(void (^)(GroupMemberListData *members, NSError *err))callback;
- (void)postSetGroupMsg:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status callback:(void (^)(NSError *err))callback;
- (void)postChangeGroupName:(int64_t)groupId newName:(NSString *)name callback:(void (^)(NSError *err))callback;
- (void)postDisBandGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;
- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;
- (void)postSetGroupPush:(int64_t)groupId pushStatus:(IMGroupPushStatus)stauts callback:(void (^)(NSError *err))callback;

#pragma mark - erroCode
- (void)registerErrorCode:(IMErrorType)code;
- (void)unregisterErrorCode:(IMErrorType)code;
- (void)callbackErrorCode:(NSInteger)errCode  errMsg:(NSString *)errMsg;

#pragma mark - net request time.
- (void)recordHttpRequestTime:(NSTimeInterval)time;
- (NSTimeInterval)getAverageRequestTime;
@end
