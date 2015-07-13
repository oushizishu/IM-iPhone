//
//  BJIMEngine.h
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BJIMEngine : NSObject

@property (nonatomic, assign, getter=isEngineActive, readonly) BOOL engineActive;

- (void)start;

- (void)stop;

@end
