//
//  BJIMManager.h
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

/**
 *  IM 管理类， 与上层交互
 */
@interface BJIMManager : NSObject

/**
 *  当前服务器环境标志变量
 */
@property (nonatomic, assign, setter=setDebugMode:, getter=getDebugMode) IMSERVER_ENVIRONMENT debugMode;

+ (instancetype)shareInstance;

#pragma mark - 登录退出 IM
/**
 *  登录 IM
 *
 *  @param userId     <#userId description#>
 *  @param userName   <#userName description#>
 *  @param userAvatar <#userAvatar description#>
 *  @param userRole   <#userRole description#>
 */
- (void)loginWithUserId:(int64_t)userId
               userName:(NSString *)userName
             userAvatar:(NSString *)userAvatar
               userRole:(IMUserRole)userRole;

/**
 *  退出 IM
 */
- (void)logout;

#pragma mark - 应用进入前后台
- (void)applicationDidEnterBackgroud;
- (void)applicationDidBecomeActive;
@end
