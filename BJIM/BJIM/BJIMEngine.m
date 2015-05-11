//
//  BJIMEngine.m
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "BJIMEngine.h"

@interface BJIMEngine()
{
    NSArray *IM_POLLING_DELTA;
    NSInteger _pollingIndex;
}

@end

@implementation BJIMEngine

- (instancetype)init
{
    self = [super init];
    if (self)
    {
       IM_POLLING_DELTA = @[@2, @2, @2, @2, @2];
    }
    return self;
}

- (void)start
{
    _engineActive = YES;
    [self nextPollingAt];
    NSLog(@"BJIMEngien  has started ");
}

- (void)stop
{
    _engineActive = NO;
    NSLog(@"BJIMEngine  had been stoped");
}


- (void)nextPollingAt
{
    if (! [self isEngineActive]) return;
    NSInteger time = [IM_POLLING_DELTA[_pollingIndex] integerValue];
    
    [self performSelector:@selector(handlePollingEvent) withObject:nil afterDelay:time];
    
    _pollingIndex = (MIN([IM_POLLING_DELTA count] - 1, _pollingIndex + 1)) % [IM_POLLING_DELTA count];
}

- (void)handlePollingEvent
{
    if (! [self isEngineActive]) return;
    
    static int index = 0;
    NSLog(@"handle polling xxxx  %d", index ++ );
    
    [self nextPollingAt];
}

- (void)resetPollingIndex
{
    _pollingIndex = 0;
}

@end
