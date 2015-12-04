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

- (void)postGetGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback;

//添加关注关系
- (void)postAddAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;
//取消关注关系
- (void)postCancelAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback;

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
