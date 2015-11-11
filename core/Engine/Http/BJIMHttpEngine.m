//
//  BJIMEngine.m
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "BJIMHttpEngine.h"
#import "NetWorkTool.h"
#import "BaseResponse.h"
#import "BJIMStorage.h"
#import "BJTimer.h"
#import "RecentContactModel.h"
#import "NSError+BJIM.h"
#import "GetGroupMemberModel.h"
#import "GroupMemberListData.h"
#import <AFNetworkReachabilityManager.h>

static int ddLogLevel = DDLogLevelVerbose;

@interface BJIMHttpEngine()
{
    NSInteger _pollingIndex;
    NSInteger _heatBeatIndex;
    BOOL _bIsPollingRequesting;
}

@property (nonatomic, strong) BJTimer *pollingTimer;
@property (nonatomic, strong) NSArray *im_polling_delta;
@end

@implementation BJIMHttpEngine

- (instancetype)init
{
    self = [super init];
    if (self)
    {
       self.im_polling_delta = @[@2, @4, @6, @8, @10];
    }
    return self;
}

- (void)start
{
    self.engineActive = YES;
    _bIsPollingRequesting = NO;
    [self resetPollingIndex];
    [self nextPollingAt];
    [self.pollingTimer.timer fire];
}

- (void)stop
{
    self.engineActive = NO;
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)syncConfig
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesSyncConfig:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            SyncConfigModel *model = [MTLJSONAdapter modelOfClass:[SyncConfigModel class] fromJSONDictionary:result.dictionaryData error:&error];
            weakSelf.im_polling_delta = model.polling_delta;
            [weakSelf.syncConfigDelegate onSyncConfig:model];
        }
        else
        {
            DDLogWarn(@"Sync Config Fail [url:%@][params:%@]", params.url, params.urlPostParams);
            [weakSelf callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Sync Config Fail [%@]", error.userInfo);
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}


- (void)postMessage:(IMMessage *)message
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesSendMessage:message succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error ;
            SendMsgModel *model = [MTLJSONAdapter modelOfClass:[SendMsgModel class] fromJSONDictionary:result.dictionaryData error:&error];
            [weakSelf.postMessageDelegate onPostMessageSucc:message result:model];
        }
        else
        {
            [weakSelf callbackErrorCode:result.code errMsg:result.msg];
            NSError *error = [[NSError alloc] initWithDomain:params.url code:result.code userInfo:@{@"msg":result.msg}];
            [weakSelf.postMessageDelegate onPostMessageFail:message error:error];
            DDLogWarn(@"Post Message Fail[url:%@][msg:%@]", params.url, params.urlPostParams);
        }
        [weakSelf checkNetworkQuality];
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Post Message Fail [url:%@][%@]", params.url, error.userInfo);
        NSError *_error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:@{@"msg":@"网络异常,请检查网络连接"}];
        [weakSelf.postMessageDelegate onPostMessageFail:message error:_error];
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        [weakSelf checkNetworkQuality];
    }];
}

- (void)postPullRequest:(int64_t)max_user_msg_id
           excludeUserMsgs:(NSString *)excludeUserMsgs
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesPostPollingRequestUserLastMsgId:max_user_msg_id excludeUserMsgIds:excludeUserMsgs group_last_msg_ids:group_last_msg_ids currentGroup:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        _bIsPollingRequesting = NO;
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            PollingResultModel *model = [MTLJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.dictionaryData error:nil];
            if (weakSelf.pollingDelegate)
            {
                [weakSelf.pollingDelegate onPollingFinish:model];
            }
            if ([model.msgs count] > 0)
            {
                [weakSelf resetPollingIndex];
            }
            
            if ([model.ops count] > 0)
            {
                // 联系人有改变，刷新联系人
                if ([model.ops[0] integerValue] == 1)
                {
                    [weakSelf syncContacts];
                }
            }
            
            if ([[IMEnvironment shareInstance] isCurrentChatToGroup] || [[IMEnvironment shareInstance] isCurrentChatToUser])
            {
                [weakSelf resetPollingIndex];
            }
            
            
            [weakSelf nextPollingAt];
        }
        else
        {
            DDLogWarn(@"Post Polling Fail [url:%@][msg:%@]", params.url, params.urlPostParams);
            [weakSelf nextPollingAt];
            [weakSelf callbackErrorCode:result.code errMsg:result.msg];
        }
        
        [weakSelf checkNetworkQuality];
        
    } failure:^(NSError *error, RequestParams *params) {
        _bIsPollingRequesting = NO;
        DDLogError(@"Post Polling Request Fail[url:%@][%@]", params.url, error.userInfo);
        [weakSelf nextPollingAt];
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        [weakSelf checkNetworkQuality];
    }];

}

- (void)nextPollingAt
{
    _heatBeatIndex = 0;
    _pollingIndex = (MIN([self.im_polling_delta count] - 1, _pollingIndex + 1)) % [self.im_polling_delta count];
}

- (void)handlePollingEvent
{
    if (! [self isEngineActive]) {
        return;
    }
    
    if (_bIsPollingRequesting) return;
    
    _heatBeatIndex ++ ;
    _heatBeatIndex = MAX(0, MIN(_heatBeatIndex, [self.im_polling_delta[_pollingIndex] integerValue]));
    if (_heatBeatIndex != [self.im_polling_delta[_pollingIndex] integerValue])
        return;
    
    if (self.postMessageDelegate == nil)
    {
        [self nextPollingAt];
    }
    else
    {
        _bIsPollingRequesting = YES;
        [self.pollingDelegate onShouldStartPolling];
    }
}

- (void)resetPollingIndex
{
    _heatBeatIndex = 0;
    _pollingIndex = -1;
}

- (BJTimer *)pollingTimer
{
    if (_pollingTimer == nil)
    {
        _pollingTimer = [BJTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handlePollingEvent) forMode:NSRunLoopCommonModes];
    }
    
    return _pollingTimer;
}

/**
 *  检查网络质量
 */
- (void)checkNetworkQuality
{
    NSTimeInterval requestAverageTime = [self getAverageRequestTime];
    if (requestAverageTime == 0) return;
    
    IMNetworkEfficiency quality = IMNetwork_Efficiency_Normal;
    
    if (requestAverageTime < 2.0)
    {
        quality = IMNetwork_Efficiency_High;
    }
    else if (requestAverageTime < 10)
    {
        quality = IMNetwork_Efficiency_Normal;
    }
    else
    {
        quality = IMNetwork_Efficiency_Low;
    }
    
    if (![[AFNetworkReachabilityManager sharedManager] isReachable]) {
        quality = IMNetwork_Efficiency_NONE;
    }
    
    if ([self.networkEfficiencyDelegate respondsToSelector:@selector(networkEfficiencyChanged:engine:)])
    {
        [self.networkEfficiencyDelegate networkEfficiencyChanged:quality engine:self];
    }
        
}

@end
