//
//  BJIMManager.m
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "BJIMManager.h"
#import "BJIMService.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <BJHL-Common-iOS-SDK/BJFileManagerTool.h>

@interface BJIMManager()
@property (nonatomic, strong) BJIMService *imService;
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
    self.imService = [[BJIMService alloc] init];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    NSCalendar *greCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //  通过已定义的日历对象，获取某个时间点的NSDateComponents表示，并设置需要表示哪些信息（NSYearCalendarUnit, NSMonthCalendarUnit, NSDayCalendarUnit等）
    NSDateComponents *dateComponents = [greCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekCalendarUnit | NSWeekdayCalendarUnit | NSWeekOfMonthCalendarUnit | NSWeekOfYearCalendarUnit fromDate:[NSDate date]];
    
    
    NSString *logDir = [NSString stringWithFormat:@"%@/%ld-%ld-%ld", [BJFileManagerTool docDir], dateComponents.year, dateComponents.month, dateComponents.day];
    
    [DDLog addLogger:[[DDFileLogger alloc] initWithLogFileManager:[[DDLogFileManagerDefault alloc] initWithLogsDirectory:logDir]]];
    // And we also enable colors
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
}

#pragma mark - 登录退出 IM
- (void)loginWithOauthToken:(NSString *)OauthToken
                     UserId:(int64_t)userId
                   userName:(NSString *)userName
                 userAvatar:(NSString *)userAvatar
                   userRole:(IMUserRole)userRole
{
    User *owner = [[User alloc] init];
    [owner setUserId:userId];
    [owner setName:userName];
    [owner setAvatar:userAvatar];
    [owner setUserRole:userRole];
    
    [[IMEnvironment shareInstance] loginWithOauthToken:OauthToken owner:owner];
    
    [self.imService startServiceWithOwner:owner];
}

- (void)logout
{
    [self.imService stopService];
    [[IMEnvironment shareInstance] logout];
}

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        return;
    }
    [self.imService sendMessage:message];
}

#pragma mark - setter & getter
- (void)setDebugMode:(IMSERVER_ENVIRONMENT)debugMode
{
    [IMEnvironment shareInstance].debugMode = debugMode;
}

- (NSArray *)getAllConversation
{
    if (! [[IMEnvironment shareInstance] isLogin])
        return nil;
 	return [self.imService getAllConversationWithOwner:[IMEnvironment shareInstance].owner];
}

#pragma mark - 应用进入前后台
- (void)applicationDidBecomeActive
{
    [self.imService applicationEnterForeground];
}

- (void)applicationDidEnterBackgroud
{
    [self.imService applicationEnterBackground];
}

@end;
