//
//  BJTaskQueue.h
//  ConditionDemo
//
//  Created by 杨磊 on 2016/12/6.
//  Copyright © 2016年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimeOutTask.h"

#define BJTaskQueue_TIMEOUT_DEFAULT 5

@interface TimeOutTaskQueue : NSObject

@property (nonatomic, assign) BOOL execEnable;
@property (nonatomic, assign) BOOL close;
@property (nonatomic, assign) NSInteger timeOutAtSeconds;

- (void)offerTask:(TimeOutTask *)task;

@end
