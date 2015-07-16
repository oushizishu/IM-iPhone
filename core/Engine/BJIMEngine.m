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
#import "SendMsgModel.h"

@interface BJIMEngine()
{
    NSInteger _pollingIndex;
}

@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) NSArray *im_polling_delta;

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
    _engineActive = YES;
    [self resetPollingIndex];
    [self.pollingTimer fire];
    NSLog(@"BJIMEngine  has started ");
}

- (void)stop
{
    _engineActive = NO;
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
    [self handlePollingEvent];
    NSLog(@"BJIMEngne has stoped");
}

- (void)syncConfig
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSyncConfig:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result.code == RESULT_CODE_SUCC)
        {
            weakSelf.im_polling_delta = result.data[@"polling_delta"];
        }
    } failure:^(NSError *error, RequestParams *params) {
       //TODO log
    }];
}

- (void)postMessage:(IMMessage *)message
{
    [NetWorkTool hermesSendMessage:message succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:responseHeaders error:nil];
        if (result.code == RESULT_CODE_SUCC)
        {
            SendMsgModel *model = [SendMsgModel modelWithDictionary:result.data error:nil];
        }
    } failure:^(NSError *error, RequestParams *params) {
        
    }];
}

- (void)postPollingRequest
{
    [self nextPollingAt];
    [self.pollingTimer fire];
}

- (void)nextPollingAt
{
    if (! [self isEngineActive]) return;
    
    _pollingIndex = (MIN([self.im_polling_delta count] - 1, _pollingIndex + 1)) % [self.im_polling_delta count];
}

- (void)handlePollingEvent
{
    static NSInteger index = 0;
    if (! [self isEngineActive]) {
        index = 0;
        return;
    }
    
    if (index == [self.im_polling_delta[_pollingIndex] integerValue])
    {
        [self.pollingTimer invalidate];
        self.pollingTimer = nil;
        index = 0;
        
        [self.pollingDelegate onShouldStartPolling];
    }
    index ++ ;
}

- (void)resetPollingIndex
{
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
