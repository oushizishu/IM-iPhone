//
//  TimeOutTask.h
//  ConditionDemo
//
//  Created by 杨磊 on 2016/12/6.
//  Copyright © 2016年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeOutTask : NSObject

@property (nonatomic, strong) NSDate *startDate;

- (instancetype)initWithRun:(void(^)())run timeOut:(void(^)())timeOut;

- (void)run;
- (void)onTimeOut;

@end
