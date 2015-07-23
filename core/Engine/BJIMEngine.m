//
//  BJIMEngine.m
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "BJIMEngine.h"
#import "NetWorkTool.h"
#import "BaseResponse.h"
#import "BJIMStorage.h"
#import "Contacts.h"
#import "BJTimer.h"

int ddLogLevel = DDLogLevelInfo;

@interface BJIMEngine()
{
    NSInteger _pollingIndex;
    NSInteger _heatBeatIndex;
    BOOL _bIsPollingRequesting;
}

@property (nonatomic, strong) BJTimer *pollingTimer;
@property (nonatomic, strong) NSArray *im_polling_delta;
@end

@implementation BJIMEngine

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
    _engineActive = YES;
    [self resetPollingIndex];
    [self nextPollingAt];
    [self.pollingTimer.timer fire];
}

- (void)stop
{
    _engineActive = NO;
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)syncConfig
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSyncConfig:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result.code == RESULT_CODE_SUCC)
        {
            weakSelf.im_polling_delta = result.data[@"polling_delta"];
//            [NetWorkTool hermesGetContactSucc:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
//                if (self.synContactDelegate) {
//                    [self.synContactDelegate synContact:response];
//                }
//            } failure:^(NSError *error, RequestParams *params) {
//            }];
        }
        else
        {
            DDLogWarn(@"Sync Config Fail [url:%@][params:%@]", params.url, params.urlPostParams);
        }
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Sync Config Fail [%@]", error.userInfo);
        
    }];
}

- (void)postMessage:(IMMessage *)message
{
    [NetWorkTool hermesSendMessage:message succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:responseHeaders error:nil];
        if (result.code == RESULT_CODE_SUCC)
        {
            SendMsgModel *model = [SendMsgModel modelWithDictionary:result.data error:nil];
            [self.postMessageDelegate onPostMessageSucc:message result:model];
        }
        else
        {
            NSError *error = [[NSError alloc] initWithDomain:params.url code:result.code userInfo:@{@"msg":result.msg}];
            [self.postMessageDelegate onPostMessageFail:message error:error];
            DDLogWarn(@"Post Message Fail[url:%@][msg:%@]", params.url, params.urlPostParams);
        }
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Post Message Fail [url:%@][%@]", params.url, error.userInfo);
        NSError *_error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:@{@"msg":@"网络异常,请检查网络连接"}];
        [self.postMessageDelegate onPostMessageFail:message error:_error];
    }];
}

- (void)postPollingRequest:(int64_t)max_user_msg_id
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId
{
    _bIsPollingRequesting = YES;
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesPostPollingRequestUserLastMsgId:max_user_msg_id group_last_msg_ids:group_last_msg_ids currentGroup:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        _bIsPollingRequesting = NO;
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result.code == RESULT_CODE_SUCC)
        {
            PollingResultModel *model = [MTLJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.data error:nil];
            if (weakSelf.pollingDelegate)
            {
                [weakSelf.pollingDelegate onPollingFinish:model];
            }
            if ([model.msgs count] > 0)
            {
                [self resetPollingIndex];
            }
            
            [self nextPollingAt];
            [self.pollingTimer.timer fire];
        }
        else
        {
            DDLogWarn(@"Post Polling Fail [url:%@][msg:%@]", params.url, params.urlPostParams);
            [self nextPollingAt];
            [self.pollingTimer.timer fire];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        _bIsPollingRequesting = NO;
        DDLogError(@"Post Polling Request Fail[url:%@][%@]", params.url, error.userInfo);
        [self nextPollingAt];
        [self.pollingTimer.timer fire];
    }];

}

- (void)getMsgConversation:(NSInteger)conversationId minMsgId:(int64_t)eid groupId:(int64_t)groupId userId:(int64_t)userId excludeIds:(NSString *)excludeIds
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesGetMsg:eid groupId:groupId uid:userId excludeMsgIds:excludeIds succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if(result.code == RESULT_CODE_SUCC)
        {
            PollingResultModel *model = [PollingResultModel modelWithDictionary:result.data error:nil];
            [weakSelf.getMsgDelegate onGetMsgSucc:conversationId result:model];
        }
        else
        {
            DDLogWarn(@"Get MSG FAIL [url:%@][%@]", params.url, params.urlPostParams);
            [weakSelf.getMsgDelegate onGetMsgFail:conversationId];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Get MSG FAIL [url:%@][%@]", params.url, error.userInfo);
        [weakSelf.getMsgDelegate onGetMsgFail:conversationId];
    }];
}

- (void)nextPollingAt
{
    _heatBeatIndex = 0;
    _pollingIndex = (MIN([self.im_polling_delta count] - 1, _pollingIndex + 1)) % [self.im_polling_delta count];
    [self.pollingTimer.timer fire];
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
    
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
    
    if (self.postMessageDelegate == nil)
    {
        [self nextPollingAt];
    }
    else
    {
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
@end
