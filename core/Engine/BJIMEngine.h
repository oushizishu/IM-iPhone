//
//  BJIMEngine.h
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMMessage.h"

#import "SyncConfigModel.h"
#import "SendMsgModel.h"
#import "PollingResultModel.h"
#import "MyContactsModel.h"
#import "PostAchiveModel.h"
#import "SyncConfigModel.h"

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

- (void)onGetMsgSucc:(NSInteger)conversationId minMsgId:(NSString *)minMsgId newEndMessageId:(NSString *)newEndMessageId result:(PollingResultModel *)model;
- (void)onGetMsgFail:(NSInteger)conversationId minMsgId:(NSString *)minMsgId;

@end

@protocol IMEngineSyncConfigDelegate <NSObject>

- (void)onSyncConfig:(SyncConfigModel *)model;

@end

typedef void(^errCodeFilterCallback)(IMErrorType errorCode, NSString *errMsg);

@interface BJIMEngine : NSObject

@property (nonatomic, assign, getter=isEngineActive, readonly) BOOL engineActive;
@property (nonatomic, weak) id<IMEnginePostMessageDelegate> postMessageDelegate;
@property (nonatomic, weak) id<IMEnginePollingDelegate> pollingDelegate;
@property (nonatomic, weak) id<IMEngineSynContactDelegate> synContactDelegate;
@property (nonatomic, weak) id<IMEngineGetMessageDelegate> getMsgDelegate;
@property (nonatomic, weak) id<IMEngineSyncConfigDelegate> syncConfigDelegate;

@property (nonatomic, copy) errCodeFilterCallback errCodeFilterCallback;

- (void)start;

- (void)stop;

- (void)syncConfig;
- (void)syncContacts;

- (void)postMessage:(IMMessage *)message;

- (void)postMessageAchive:(IMMessage *)message;

- (void)postPollingRequest:(int64_t)max_user_msg_id
           excludeUserMsgs:(NSString *)excludeUserMsgs
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId;

- (void)getMsgConversation:(NSInteger)conversationId
                  minMsgId:(NSString *)eid
                   groupId:(int64_t)groupId
                    userId:(int64_t)userId
                excludeIds:(NSString *)excludeIds
            startMessageId:(NSString *)startMessageId;

- (void)postChangeRemarkName:(NSString *)remarkName
                      userId:(int64_t)userId
                    userRole:(IMUserRole)userRole
                    callback:(void(^)(NSString *remarkName, NSString *remarkHeader, NSInteger errCode, NSString *errMsg))callback;

- (void)postGetUserInfo:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(User *result))callback;

- (void)postGetGroupProfile:(int64_t)groupId callback:(void(^)(Group *result))callback;

#pragma mark - group
- (void)postGetGroupMembers:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index callback:(void (^)(GroupMemberListData *members, NSError *err))callback;
- (void)postSetGroupMsg:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status callback:(void (^)(NSError *err))callback;
- (void)postChangeGroupName:(int64_t)groupId newName:(NSString *)name callback:(void (^)(NSError *err))callback;
- (void)postDisBandGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;
- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;

#pragma mark - erroCode
- (void)registerErrorCode:(IMErrorType)code;
- (void)unregisterErrorCode:(IMErrorType)code;
@end
