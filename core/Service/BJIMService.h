//
//  BJIMService.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "BJIMEngine.h"
#import "BJIMStorage.h"
#import "IMMessage.h"


@interface BJIMService : NSObject

@property (nonatomic, strong, readonly) BJIMEngine *imEngine;
@property (nonatomic, strong, readonly) BJIMStorage *imStorage;

- (void)startServiceWithOwner:(User *)owner;

- (void)stopService;

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message;
- (void)retryMessage:(IMMessage *)message;

- (void)applicationEnterBackground;
- (void)applicationEnterForeground;
@end
