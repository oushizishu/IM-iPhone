//
//  BJIMManager.m
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "BJIMManager.h"
#import "BJIMEngine.h"

@interface BJIMManager()

@property (nonatomic, strong) BJIMEngine *imEngine;

@end

@implementation BJIMManager

+(instancetype)shareInstance
{
    static BJIMManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[super alloc] init];
        [_sharedInstance initialize];
    });
    return _sharedInstance;
}

- (void)initialize
{

}

#pragma mark - 登录退出 IM
- (void)loginWithUserId:(int64_t)userId
               userName:(NSString *)userName
             userAvatar:(NSString *)userAvatar
               userRole:(IMUserRole)userRole
{
    [self.imEngine start];
}

- (void)logout
{
    [self.imEngine stop];
}

#pragma mark - 应用进入前后台
- (void)applicationDidBecomeActive
{
    [self.imEngine start];
}

- (void)applicationDidEnterBackgroud
{
    [self.imEngine stop];
}

#pragma mark - Setter & Getter
- (BJIMEngine *)imEngine
{
    if (_imEngine == nil)
    {
        _imEngine = [[BJIMEngine alloc] init];
    }
    return _imEngine;
}

@end;
