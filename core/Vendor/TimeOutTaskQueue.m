//
//  BJTaskQueue.m
//  ConditionDemo
//
//  Created by 杨磊 on 2016/12/6.
//  Copyright © 2016年 杨磊. All rights reserved.
//

#import "TimeOutTaskQueue.h"

@interface TimeOutTaskQueue()

@property (nonatomic, strong) NSThread *thread;
@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSMutableArray<TimeOutTask *> *taskQueue;

@end

@implementation TimeOutTaskQueue

- (void)dealloc
{
    [_condition unlock];
    [_thread cancel];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _taskQueue = [[NSMutableArray alloc] initWithCapacity:5];
        _condition = [[NSCondition alloc] init];
        _timeOutAtSeconds = BJTaskQueue_TIMEOUT_DEFAULT;
    }
    return self;
}

- (void)setExecEnable:(BOOL)execEnable
{
    [_condition lock];
    _execEnable = execEnable;
    [_condition signal];
    [_condition unlock];
}

- (void)setClose:(BOOL)close
{
    [_condition lock];
    _close = close;
    [_condition signal];
    [_condition unlock];
}

- (void)run
{
    while ([_taskQueue count] > 0 && ![[NSThread currentThread] isCancelled]) {
        
        TimeOutTask *task = [_taskQueue objectAtIndex:0];
        
        if (!_close) {
            NSDate *date = [NSDate date];
            NSTimeInterval delta = _timeOutAtSeconds - ([date timeIntervalSince1970] - [task.startDate timeIntervalSince1970]);
        
            date = [NSDate dateWithTimeIntervalSinceNow:delta];
        
            [_condition lock];
            if (!_execEnable) {
                [_condition waitUntilDate:date];
            }
            [_condition unlock];
        }
        
        if (!_close && _execEnable) {
            [task run];
        } else {
            [task onTimeOut];
        }
        [_taskQueue removeObject:task];
    }
}

- (void)offerTask:(TimeOutTask *)task
{
    task.startDate = [NSDate date];
    [_taskQueue addObject:task];
    
    if (_thread == nil || [_thread isFinished]) {
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [_thread start];
    }
}

@end
