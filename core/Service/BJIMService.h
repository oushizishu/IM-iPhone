//
//  BJIMService.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface BJIMService : NSObject

- (void)startServiceWithOwner:(User *)owner;

- (void)stopService;

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message;

- (void)applicationEnterBackground;
- (void)applicationEnterForeground;
@end
