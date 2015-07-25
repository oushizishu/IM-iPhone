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

@protocol IMEnginePostMessageDelegate <NSObject>

- (void)onPostMessageSucc:(IMMessage *)message result:(SendMsgModel *)model;
- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error;

@end

@protocol IMEngineSynContactDelegate <NSObject>

- (void)didSyncContacts:(MyContactsModel *)model;

@end

@protocol IMEnginePollingDelegate <NSObject>

- (void)onShouldStartPolling;

- (void)onPollingFinish:(PollingResultModel *)model;

@end

@protocol  IMEngineGetMessageDelegate <NSObject>

- (void)onGetMsgSucc:(NSInteger)conversationId minMsgId:(double_t)minMsgId result:(PollingResultModel *)model;
- (void)onGetMsgFail:(NSInteger)conversationId minMsgId:(double_t)minMsgId;


@end

@interface BJIMEngine : NSObject

@property (nonatomic, assign, getter=isEngineActive, readonly) BOOL engineActive;
@property (nonatomic, weak) id<IMEnginePostMessageDelegate> postMessageDelegate;
@property (nonatomic, weak) id<IMEnginePollingDelegate> pollingDelegate;
@property (nonatomic, weak) id<IMEngineSynContactDelegate> synContactDelegate;
@property (nonatomic, weak) id<IMEngineGetMessageDelegate> getMsgDelegate;

- (void)start;

- (void)stop;

- (void)syncConfig;
- (void)syncContacts;

- (void)postMessage:(IMMessage *)message;

- (void)postPollingRequest:(int64_t)max_user_msg_id
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId;

- (void)getMsgConversation:(NSInteger)conversationId
                  minMsgId:(int64_t)eid
                   groupId:(int64_t)groupId
                    userId:(int64_t)userId
                excludeIds:(NSString *)excludeIds;

@end
