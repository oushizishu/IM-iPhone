//
//  TimeOutTask.m
//  ConditionDemo
//
//  Created by 杨磊 on 2016/12/6.
//  Copyright © 2016年 杨磊. All rights reserved.
//

#import "TimeOutTask.h"

typedef void (^TaskBlock)();

@interface TimeOutTask()

@property (nonatomic, copy) TaskBlock runBlock;
@property (nonatomic, copy) TaskBlock timeOutBlock;

@end

@implementation TimeOutTask

- (instancetype)initWithRun:(void (^)())run timeOut:(void (^)())timeOut
{
    self = [super init];
    if (self) {
        _runBlock = run;
        _timeOutBlock = timeOut;
    }
    return self;
}

- (void)run
{
    if (_runBlock) {
        _runBlock();
    }
}

- (void)onTimeOut
{
    if (_timeOutBlock) {
        _timeOutBlock();
    }
}
@end
