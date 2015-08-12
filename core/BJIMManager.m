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
#import "BJIMService+GroupManager.h"
#import "NSError+BJIM.h"
#import "GroupMember.h"

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
    NSAssert([OauthToken length] > 0, @"IMAuthToken  must not be null.");
    
    if ([OauthToken isEqualToString:[IMEnvironment shareInstance].oAuthToken] &&
        [IMEnvironment shareInstance].owner != nil &&
        [IMEnvironment shareInstance].owner.userId == userId &&
        [IMEnvironment shareInstance].owner.userRole == userRole &&
        self.imService.bIsServiceActive)
    {
        // 重复登录，节省资源
        [IMEnvironment shareInstance].owner.name = userName;
        [IMEnvironment shareInstance].owner.avatar = userAvatar;
        return;
    }
    
    
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

- (void)loadMessageFromMinMsgId:(NSString *)minMsgId inConversation:(Conversation *)conversation
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

- (NSInteger)getAllConversationUnreadNum
{
    if (! [[IMEnvironment shareInstance] isLogin])
        return 0;
    return [self.imService getAllConversationUnReadNumWithUser:[IMEnvironment shareInstance].owner];
}

- (Conversation *)getConversationUserId:(int64_t)userId role:(IMUserRole)userRole
{
    if (! [[IMEnvironment shareInstance] isLogin])
        return nil;
    return [self.imService getConversationUserOrGroupId:userId userRole:userRole owner:[IMEnvironment shareInstance].owner chat_t:eChatType_Chat];
}

- (BOOL)deleteConversation:(Conversation *)conversation
{
    if (! [[IMEnvironment shareInstance] isLogin])
        return NO;
    if (conversation == nil) return NO;
    return [self.imService deleteConversation:conversation owner:[IMEnvironment shareInstance].owner];
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

- (void)setUser:(User *)user
{
    if (! [[IMEnvironment shareInstance] isLogin]) return ;
    if (user == nil) return;
    [self.imService setUser:user];
}

#pragma mark - 备注名
- (void)setRemarkName:(NSString *)remarkName
                 user:(User *)user
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback
{
    if (! [[IMEnvironment shareInstance] isLogin]) return;
    [self.imService setRemarkName:remarkName user:user callback:callback];
}

//TODO
//- (void)setRemarkName:(NSString *)remarkName
//                group:(Group *)group
//             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback
//{
//    if (! [[IMEnvironment shareInstance] isLogin]) return;
//    [self.imService setRemarkName:remarkName group:group callback:callback];
//}

#pragma mark - 系统小秘书 & 客服
- (User *)getSystemSecretary
{
    if (! [[IMEnvironment shareInstance] isLogin]) return nil;
    return [self.imService getSystemSecretary];
}

- (User *)getCustomWaiter
{
    if (! [[IMEnvironment shareInstance] isLogin]) return nil;
    return [self.imService getCustomWaiter];
}

- (BOOL)isMyTeacher:(int64_t)teacherId
{
    if (! [[IMEnvironment shareInstance] isLogin]) return NO;
    return [self.imService hasTeacher:teacherId ofUser:[IMEnvironment shareInstance].owner];
}

- (BOOL)isMyGroup:(int64_t)groupId
{
    if (! [[IMEnvironment shareInstance] isLogin]) return NO;
    return [self.imService getGroupMember:groupId ofUser:[IMEnvironment shareInstance].owner] != nil;
}

- (IMGroupMsgStatus)getGroupMsgStatus:(int64_t)groupId
{
    if (! [[IMEnvironment shareInstance] isLogin]) return eGroupMsg_All;
    GroupMember *member = [self.imService getGroupMember:groupId ofUser:[IMEnvironment shareInstance].owner];
    return member.msgStatus;
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

- (void)addRecentContactsDelegate:(id)delegate
{
    [self.imService addRecentContactsDelegate:delegate];
}

- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate
{
    [self.imService addUserInfoChangedDelegate:delegate];
}

- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate
{
    [self.imService addGroupProfileChangedDelegate:delegate];
}

@end;

@implementation BJIMManager (GroupManager)
- (void)addGroupManagerDelegate:(id<IMGroupManagerResultDelegate>)delegate;
{
    [self.imService addGroupManagerDelegate:delegate];
}

- (void)getGroupProfile:(int64_t)groupId;
{
    if (![[IMEnvironment shareInstance] isLogin]) {
        [self.imService notifyGetGroupProfile:groupId group:nil error:[NSError bjim_loginError]];
        return;
    }
    [self.imService getGroupProfile:groupId];
}

- (void)leaveGroupWithGroupId:(int64_t)groupId;
{
    if (![[IMEnvironment shareInstance] isLogin]) {
        [self.imService notifyLeaveGroup:groupId error:[NSError bjim_loginError]];
        return;
    }
    [self.imService leaveGroupWithGroupId:groupId];
    
}

- (void)disbandGroupWithGroupId:(int64_t)groupId;
{
    if (![[IMEnvironment shareInstance] isLogin]) {
        [self.imService notifyDisbandGroup:groupId error:[NSError bjim_loginError]];
        return;
    }
    [self.imService disbandGroupWithGroupId:groupId];
}

- (void)getGroupMemberWithGroupId:(int64_t)groupId page:(NSUInteger)page;
{
    if (![[IMEnvironment shareInstance] isLogin]) {
        [self.imService notifyGetGroupMembers:nil userRole:eUserRole_Anonymous page:page groupId:groupId error:[NSError bjim_loginError]];
        return;
    }
    [self.imService getGroupMemberWithGroupId:groupId userRole:eUserRole_Anonymous page:page];
}

- (void)getGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)page;
{
    if (![[IMEnvironment shareInstance] isLogin]) {
        [self.imService notifyGetGroupMembers:nil userRole:userRole page:page groupId:groupId error:[NSError bjim_loginError]];
        return;
    }
    [self.imService getGroupMemberWithGroupId:groupId userRole:userRole page:page];
}


- (void)changeGroupName:(NSString *)name groupId:(int64_t)groupId;
{
    if (![[IMEnvironment shareInstance] isLogin]) {
        [self.imService notifyChangeGroupName:name groupId:groupId error:[NSError bjim_loginError]];
        return;
    }
    [self.imService changeGroupName:name groupId:groupId];
}

- (void)setGroupMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId;
{
    if (![[IMEnvironment shareInstance] isLogin]) {
        [self.imService notifyChangeMsgStatus:status groupId:groupId error:[NSError bjim_loginError]];
        return;
    }
    [self.imService setGroupMsgStatus:status groupId:groupId];
}

@end

