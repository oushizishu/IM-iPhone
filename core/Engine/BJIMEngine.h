//
//  BJIMEngine.h
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMMessage.h"

@protocol IMEnginePostMessageDelegate <NSObject>

- (void)onPostMessageSucc:(IMMessage *)message;
- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error;

@end

@interface BJIMEngine : NSObject

@property (nonatomic, assign, getter=isEngineActive, readonly) BOOL engineActive;
@property (nonatomic, weak) id<IMEnginePostMessageDelegate> postMessageDelegate;

- (void)start;

- (void)stop;

- (void)postMessage:(IMMessage *)message;

@end
