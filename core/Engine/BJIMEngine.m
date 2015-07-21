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
int ddLogLevel = DDLogLevelInfo;

@interface BJIMEngine()
{
    NSInteger _pollingIndex;
    NSInteger _heatBeatIndex;
    BOOL _bIsPollingRequesting;
}

@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) NSArray *im_polling_delta;
@property (nonatomic, strong) BJIMStorage *storage;
@end

@implementation BJIMEngine

- (instancetype)init
{
    self = [super init];
    if (self)
    {
       self.im_polling_delta = @[@2, @2, @4, @6, @8];
    }
    return self;
}

- (void)start
{
    if ([self isEngineActive]) return;
    if (!self.storage) {
        self.storage = [[BJIMStorage alloc] init];
    }
    _engineActive = YES;
    [self resetPollingIndex];
    [self.pollingTimer fire];
}

- (void)stop
{
    _engineActive = NO;
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
    [self handlePollingEvent];
}

- (void)syncConfig
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSyncConfig:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result.code == RESULT_CODE_SUCC)
        {
            weakSelf.im_polling_delta = result.data[@"polling_delta"];
            [NetWorkTool hermesGetContactSucc:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
                if (self.synContactDelegate) {
                    [self.synContactDelegate synContact:response];
                }
            } failure:^(NSError *error, RequestParams *params) {
            }];
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
        [self.postMessageDelegate onPostMessageFail:message error:error];
    }];
}

- (void)postPollingRequest
{
    _bIsPollingRequesting = YES;
    [self nextPollingAt];
    [self.pollingTimer fire];
}

- (void)nextPollingAt
{
    _heatBeatIndex = 0;
    _pollingIndex = (MIN([self.im_polling_delta count] - 1, _pollingIndex + 1)) % [self.im_polling_delta count];
    [self.pollingTimer fire];
}

- (void)handlePollingEvent
{
    if (_bIsPollingRequesting) return;
    
    _heatBeatIndex ++ ;
    _heatBeatIndex = MAX(0, MIN(_heatBeatIndex, [self.im_polling_delta[_pollingIndex] integerValue]));
    if (_heatBeatIndex != [self.im_polling_delta[_pollingIndex] integerValue])
        return;
    
    if (! [self isEngineActive]) {
        return;
    }
    
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
    _pollingIndex = 0;
}

- (NSTimer *)pollingTimer
{
    if (_pollingTimer == nil)
    {
        _pollingTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(handlePollingEvent) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_pollingTimer forMode:NSDefaultRunLoopMode];
    }
    
    return _pollingTimer;
}
@end
