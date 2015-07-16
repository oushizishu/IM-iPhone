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


@protocol IMEnginePostMessageDelegate <NSObject>

- (void)onPostMessageSucc:(IMMessage *)message result:(SendMsgModel *)model;
- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error;

@end

@protocol IMEnginePollingDelegate <NSObject>

- (void)onShouldStartPolling;

- (void)onPollingFinish;

@end

@interface BJIMEngine : NSObject

@property (nonatomic, assign, getter=isEngineActive, readonly) BOOL engineActive;
@property (nonatomic, weak) id<IMEnginePostMessageDelegate> postMessageDelegate;
@property (nonatomic, weak) id<IMEnginePollingDelegate> pollingDelegate;

- (void)start;

- (void)stop;

- (void)syncConfig;

- (void)postMessage:(IMMessage *)message;

@end
