//
//  BJIMEngine.m
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "BJIMEngine.h"
#import "NetWorkTool.h"

@interface BJIMEngine()
{
    NSArray *IM_POLLING_DELTA;
    NSInteger _pollingIndex;
}

@property (nonatomic, strong) NSTimer *pollingTimer;

@end

@implementation BJIMEngine

- (instancetype)init
{
    self = [super init];
    if (self)
    {
       IM_POLLING_DELTA = @[@2, @2, @4, @6, @8];
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


- (void)nextPollingAt
{
    if (! [self isEngineActive]) return;
    
    _pollingIndex = (MIN([IM_POLLING_DELTA count] - 1, _pollingIndex + 1)) % [IM_POLLING_DELTA count];
}

- (void)handlePollingEvent
{
    static NSInteger index = 0;
    if (! [self isEngineActive]) {
        index = 0;
        return;
    }
    
    if (index == [IM_POLLING_DELTA[_pollingIndex] integerValue])
    {
        [self.pollingTimer invalidate];
        self.pollingTimer = nil;
        index = 0;
        //TODO handle event
        NSLog(@"handle xxxxxxxx  %@", [NSDate date]);
        [self nextPollingAt];
        [self.pollingTimer fire];
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
