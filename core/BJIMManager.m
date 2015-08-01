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
//    [DDLog addLogger:[DDTTYLogger sharedInstance]];
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
    message.sender= [IMEnvironment shareInstance].owner.userId;
    message.senderRole = [IMEnvironment shareInstance].owner.userRole;
    message.createAt = [[NSDate date] timeIntervalSince1970];
    [self.imService sendMessage:message];
}

- (void)retryMessage:(IMMessage *)message
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        return;
    }
    [self.imService retryMessage:message];
}

//- (void)loadMoreMessages:(Conversation *)conversation
//{
//    if (! [[IMEnvironment shareInstance] isLogin])
//    {
//        return;
//    }
//    [self.imService loadMoreMessages:conversation];
//}

- (void)loadMessageFromMinMsgId:(double_t)minMsgId inConversation:(Conversation *)conversation
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        return ;
    }
    [self.imService loadMessages:conversation minMsgId:minMsgId];
}

- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole
{
    return [self.imService getUser:userId role:userRole];
}

- (Group *)getGroup:(int64_t)groupId
{
    return [self.imService getGroup:groupId];
}

#pragma mark - current chat
- (void)startChatToUserId:(int64_t)userId role:(IMUserRole)userRole
{
    [IMEnvironment shareInstance].currentChatToUserId = userId;
    [IMEnvironment shareInstance].currentChatToUserRole = userRole;
    [IMEnvironment shareInstance].currentChatToGroupId = -1;
}

- (void)startChatToGroup:(int64_t)groupId
{
    [IMEnvironment shareInstance].currentChatToUserId = -1;
    [IMEnvironment shareInstance].currentChatToUserRole = -1;
    [IMEnvironment shareInstance].currentChatToGroupId = groupId;
}

- (void)stopChat
{
    [IMEnvironment shareInstance].currentChatToUserId = -1;
    [IMEnvironment shareInstance].currentChatToUserRole = -1;
    [IMEnvironment shareInstance].currentChatToGroupId = -1;
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

- (Conversation *)getConversationGroupId:(int64_t)groupId
{
    if (! [[IMEnvironment shareInstance] isLogin])
        return nil;
    return [self.imService getConversationUserOrGroupId:groupId userRole:eUserRole_Anonymous owner:[IMEnvironment shareInstance].owner chat_t:eChatType_GroupChat];
}

- (Conversation *)getConversationUserId:(int64_t)userId role:(IMUserRole)userRole
{
    if (! [[IMEnvironment shareInstance] isLogin])
        return nil;
    return [self.imService getConversationUserOrGroupId:userId userRole:userRole owner:[IMEnvironment shareInstance].owner chat_t:eChatType_Chat];
}

#pragma makr - 联系人
- (NSArray *)getMyGroups
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        return nil;
    }
    return [self.imService getGroupsWithUser:[IMEnvironment shareInstance].owner];
}

- (NSArray *)getMyTeacherContacts
{
    if (! [[IMEnvironment shareInstance] isLogin]) return nil;
    if ([IMEnvironment shareInstance].owner.userRole == eUserRole_Teacher) return nil;
    
    return [self.imService getTeacherContactsWithUser:[IMEnvironment shareInstance].owner];
}

- (NSArray *)getMyStudentContacts
{
    if (! [[IMEnvironment shareInstance] isLogin]) return nil;
    if ([IMEnvironment shareInstance].owner.userRole == eUserRole_Student) return nil;
    
    return [self.imService getStudentContactsWithUser:[IMEnvironment shareInstance].owner];
}

- (NSArray *)getMyInstitutionContacts
{
    if (! [[IMEnvironment shareInstance] isLogin]) return nil;
    if ([IMEnvironment shareInstance].owner.userRole == eUserRole_Institution) return nil;
    return [self.imService getInstitutionContactsWithUser:[IMEnvironment shareInstance].owner];
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
#pragma mark - add Delegates
- (void)addConversationChangedDelegate:(id<IMConversationChangedDelegate>)delegate
{
    [self.imService addConversationChangedDelegate:delegate];
}

- (void)addReceiveNewMessageDelegate:(id<IMReceiveNewMessageDelegate>)delegate
{
    [self.imService addReceiveNewMessageDelegate:delegate];
}

- (void)addDeliveryMessageDelegate:(id<IMDeliveredMessageDelegate>)delegate
{
    [self.imService addDeliveryMessageDelegate:delegate];
}

- (void)addCmdMessageDelegate:(id<IMCmdMessageDelegate>)delegate
{
    [self.imService addCmdMessageDelegate:delegate];
}

- (void)addContactChangedDelegate:(id<IMContactsChangedDelegate>)delegate
{
    [self.imService addContactChangedDelegate:delegate];
}

- (void)addLoadMoreMessagesDelegate:(id<IMLoadMessageDelegate>)delegate
{
    [self.imService addLoadMoreMessagesDelegate:delegate];
}

@end;
