//
//  BJIMService.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "BJIMService.h"
#import <BJHL-Common-iOS-SDK/BJCommonDefines.h>
#import "Conversation+DB.h"
#import "IMEnvironment.h"
#import "BJIMStorage.h"
#import "IMMessage+DB.h"
#import "GroupMember.h"


#import "SendMsgOperation.h"
#import "HandlePostMessageSuccOperation.h"
#import "PrePollingOperation.h"
#import "HandlePollingResultOperation.h"
#import "LoadMoreMessagesOperation.h"
#import "HandleGetMsgOperation.h"
#import "SyncContactOperation.h"
#import "RetryMessageOperation.h"
#import "ResetConversationUnreadNumOperation.h"
#import "ResetMsgIdOperation.h"
#import "SetSocialFocusOperation.h"

#import "BJIMAbstractEngine.h"
#import "BJIMHttpEngine.h"
#import "BJIMSocketEngine.h"

#import "NetWorkTool.h"
#import "BaseResponse.h"
#import "PassiveBlacklistOperation.h"

@interface BJIMService()<IMEnginePostMessageDelegate,
                         IMEngineSynContactDelegate,
                         IMEnginePollingDelegate,
                         IMEngineGetMessageDelegate,
                         IMEngineSyncConfigDelegate,
                         IMEngineNetworkEfficiencyDelegate>


@property (nonatomic, strong) NSHashTable *contactStateDelegates;
@property (nonatomic, strong) NSHashTable *conversationDelegates;
@property (nonatomic, strong) NSHashTable *receiveNewMessageDelegates;
@property (nonatomic, strong) NSHashTable *deliveredMessageDelegates;
@property (nonatomic, strong) NSHashTable *cmdMessageDelegates;
@property (nonatomic, strong) NSHashTable *contactChangedDelegates;
@property (nonatomic, strong) NSHashTable *loadMoreMessagesDelegates;
@property (nonatomic, strong) NSHashTable *recentContactsDelegates;
@property (nonatomic, strong) NSHashTable *userInfoDelegates;
@property (nonatomic, strong) NSHashTable *groupInfoDelegates;
@property (nonatomic, strong) NSHashTable *disconnectionStateDelegates;
@property (nonatomic, strong) NSHashTable *imLoginLogoutDelegates;
@property (nonatomic, strong) NSHashTable *imUnReadNumChangedDelegates;

@property (nonatomic, strong) User *systemSecretary;
@property (nonatomic, strong) User *customeWaiter;
@property (nonatomic, strong) User *stanger;
@property (nonatomic, strong) User *nFans;

@property (nonatomic, strong, readonly) NSOperationQueue *readOperationQueue; //DB 读操作线程
@property (nonatomic, strong, readonly) NSOperationQueue *sendMessageOperationQueue; // 消息发送在独立线程上操作
@property (nonatomic, strong, readonly) NSOperationQueue *receiveMessageOperationQueue; // 接受消息在独立线程上操作
@property (nonatomic, strong, readonly) NSOperationQueue *syncContactsOperationQueue; // 联系人数据量比较大， 放在单独线程中

@end

@implementation BJIMService
@synthesize imEngine=_imEngine;
@synthesize imStorage=_imStorage;
@synthesize readOperationQueue=_readOperationQueue;
@synthesize writeOperationQueue=_writeOperationQueue;
@synthesize sendMessageOperationQueue=_sendMessageOperationQueue;
@synthesize receiveMessageOperationQueue=_receiveMessageOperationQueue;
@synthesize syncContactsOperationQueue=_syncContactsOperationQueue;

- (void)startServiceWithOwner:(User *)owner
{
    self.bIsServiceActive = YES;
   
    [self.imStorage.userDao insertOrUpdateUser:owner];
    
    [self startEngine];
    
    // bugfix
    /** 初始化启动 msgId 修改线程。老版本中包含部分 msgId 没有做对齐处理。在线程中修复数据.
     修复过一次以后就不再需要了*/
    if (! [[NSUserDefaults standardUserDefaults] valueForKey:@"ResetMsgIdOperation"])
    {
        ResetMsgIdOperation *operation = [[ResetMsgIdOperation alloc] init];
        operation.imService = self;
        [self.writeOperationQueue addOperation:operation];
    }
}

- (void)startEngine
{
    self.imEngine.pollingDelegate = self;
    self.imEngine.postMessageDelegate = self;
    self.imEngine.getMsgDelegate = self;
    self.imEngine.synContactDelegate = self;
    self.imEngine.syncConfigDelegate = self;
    self.imEngine.networkEfficiencyDelegate = self;
    
    [self.imEngine start];
    
    [self.imEngine syncConfig];
    [self.imEngine syncContacts];
    
    __WeakSelf__ weakSelf = self;
    self.imEngine.errCodeFilterCallback = ^(IMErrorType code, NSString *errMsg){
        [weakSelf notifyErrorCode:code msg:errMsg];
    };
    
    [self.imEngine registerErrorCode:eError_token_invalid];
}

- (void)stopEngine
{
    [self.imEngine stop];
    
    self.imEngine.pollingDelegate = nil;
    self.imEngine.postMessageDelegate = nil;
    self.imEngine.getMsgDelegate = nil;
    self.imEngine.synContactDelegate = nil;
    self.imEngine.syncConfigDelegate = nil;
    self.imEngine.networkEfficiencyDelegate = nil;
    
    [self.imEngine unregisterErrorCode:eError_token_invalid];
    self.imEngine.errCodeFilterCallback = nil;
}

- (void)stopService
{
    [self.readOperationQueue cancelAllOperations];
    [self.writeOperationQueue cancelAllOperations];
    
    self.bIsServiceActive = NO;
    
    [self stopEngine];
    
    self.systemSecretary = nil;
    self.customeWaiter = nil;
   
    [self.imStorage clearSession];
}

/**
 *  当退出聊天界面时， 队列中的 getMsg 的 operation 可能还没有开始执行。可以将其取消
 */
//- (void)removeOperationsWhileStopChat
//{
//    for (NSOperation *operation in [self.writeOperationQueue operations]) {
//        if ([operation isKindOfClass:[HandleGetMsgOperation class]])
//        {
//            [operation cancel];
//        }
//    }
//}

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message
{
    message.status = eMessageStatus_Sending;
    message.imService = self;
    SendMsgOperation *operation = [[SendMsgOperation alloc] init];
    operation.message = message;
    operation.imService = self;
    [self.sendMessageOperationQueue addOperation:operation]; //放在发送消息队列中
    
    [self notifyWillDeliveryMessage:message];
}

- (void)retryMessage:(IMMessage *)message
{
    message.status = eMessageStatus_Sending;
    message.imService = self;
    RetryMessageOperation *operation = [[RetryMessageOperation alloc] init];
    operation.message = message;
    operation.imService = self;
    [self.sendMessageOperationQueue addOperation:operation]; // 放在发送消息队列中
    
    [self notifyWillDeliveryMessage:message];
}

- (void)loadMessagesUser:(User *)user orGroup:(Group *)group minMsgId:(NSString *)minMsgId
{
    LoadMoreMessagesOperation *operation = [[LoadMoreMessagesOperation alloc] init];
    
    operation.minMsgId = minMsgId;
    operation.imService = self;
    operation.chatToGroup = group;
    operation.chatToUser = user;
//    [self.operationQueue addOperation:operation];
    [self.readOperationQueue addOperation:operation];
}

#pragma mark - Post Message Delegate
- (void)onPostMessageSucc:(IMMessage *)message result:(SendMsgModel *)model
{
    if (!self.bIsServiceActive) return;
    
    HandlePostMessageSuccOperation *operation = [[HandlePostMessageSuccOperation alloc] init];
    operation.imService = self;
    operation.message = message;
    operation.model = model;
    
    [self.sendMessageOperationQueue addOperation:operation];
}

- (void)onPostMessageAchiveSucc:(IMMessage *)message result:(PostAchiveModel *)model
{
    if (!self.bIsServiceActive) return;
    if (message.msg_t == eMessageType_AUDIO)
    {
        IMAudioMessageBody *messageBody = (IMAudioMessageBody *)message.messageBody;
        messageBody.url = model.url;
    }
    else if (message.msg_t == eMessageType_IMG)
    {
        IMImgMessageBody *messageBody = (IMImgMessageBody *)message.messageBody;
        messageBody.url = model.url;
    }
    [self.imStorage.messageDao update:message];
    [self.imEngine postMessage:message];
}

- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error
{
    if (! self.bIsServiceActive) return;
    
    message.status = eMessageStatus_Send_Fail;
    [self.imStorage.messageDao update:message];
    
    [self notifyDeliverMessage:message errorCode:error.code error:[error.userInfo valueForKey:@"msg"]];
    
    //如果是由于被对方拉黑发送失败，调用PassiveBlacklistOperation。
    if(false)
    {
        PassiveBlacklistOperation *passiveOperation = [[PassiveBlacklistOperation alloc] init];
        passiveOperation.message = message;
        passiveOperation.imService = self;
        
        [self.writeOperationQueue addOperation:passiveOperation];
    }
}

#pragma mark - Polling Delegate
- (void)onShouldStartPolling
{
    if (! self.bIsServiceActive) return;
    PrePollingOperation *operation = [[PrePollingOperation alloc] init];
    operation.imService = self;
//    [self.operationQueue addOperation:operation];
    [self.readOperationQueue addOperation:operation];
}

- (void)onPollingFinish:(PollingResultModel *)model
{
    if (! self.bIsServiceActive) return;
    
    if (! model) return;
    
    HandlePollingResultOperation *operation = [[HandlePollingResultOperation alloc] init];
    operation.imService = self;
    operation.model = model;
    [self.receiveMessageOperationQueue addOperation:operation]; //接收到消息在独立线程上操作
}

#pragma mark - get Msg Delegate
- (void)onGetMsgSuccMinMsgId:(NSString *)minMsgId
                      userId:(int64_t)userId
                    userRole:(IMUserRole)userRole
                     groupId:(int64_t)groupId
                      result:(PollingResultModel *)model
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.model = model;
    operation.minMsgId = minMsgId;
    operation.userId = userId;
    operation.userRole = userRole;
    operation.groupId = groupId;
    
    [self.receiveMessageOperationQueue addOperation:operation];
}

- (void)onGetMsgFailMinMsgId:(NSString *)minMsgId
                      userId:(int64_t)userId
                    userRole:(IMUserRole)userRole
                     groupId:(int64_t)groupId
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.minMsgId = minMsgId;
    operation.groupId = groupId;
    operation.userId = userId;
    operation.userRole = userRole;
    
    [self.receiveMessageOperationQueue addOperation:operation];
}

#pragma mark syncContact 
- (void)didSyncContacts:(MyContactsModel *)model
{
    if (! self.bIsServiceActive) return;

    SyncContactOperation *operation = [[SyncContactOperation alloc]init];
    operation.imService = self;
    operation.model = model;
    [self.syncContactsOperationQueue addOperation:operation];
}

#pragma mark - syncConfigDelegate
- (void)onSyncConfig:(SyncConfigModel *)model
{
    User *system = [self getSystemSecretary];
    system.userId = model.systemSecretary.number;
    system.userRole = (IMUserRole)model.systemSecretary.role;
    
    User *waiter = [self getCustomWaiter];
    waiter.userId = model.customWaiter.number;
    waiter.userRole = (IMUserRole)model.customWaiter.role;
}

#pragma mark - network efficiency delegate
- (void)networkEfficiencyChanged:(IMNetworkEfficiency)efficiency engine:(BJIMAbstractEngine *)engine
{
    if ([engine isKindOfClass:[BJIMHttpEngine class]])
    {
        if (efficiency == IMNetwork_Efficiency_High || efficiency == IMNetwork_Efficiency_Normal)
        {
            // 短连接模式下，网络速率良好. 改用 socket 连接
            [self stopEngine];
            _imEngine = [[BJIMSocketEngine alloc] init];
            [self startEngine];
        }
    }
    else
    {
        if (efficiency == IMNetwork_Efficiency_Low)
        {
            // 长连接模式下，网络连接效率底下。改为短链接
            [self stopEngine];
            _imEngine = [[BJIMHttpEngine alloc] init];
            [self startEngine];
        }
    }
}


#pragma mark - Setter & Getter
#pragma mark -- conversation
- (NSArray *)getAllConversationWithOwner:(User *)owner
{
    NSArray *list = [self.imStorage.conversationDao loadAllWithOwnerId:owner.userId userRole:owner.userRole];
    
    __WeakSelf__ weakSelf = self;
    [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Conversation *conversation = (Conversation *)obj;
        conversation.imService = weakSelf;
    }];
    return list;
}

- (Conversation *)getConversationUserOrGroupId:(int64_t)userOrGroupId
                                      userRole:(IMUserRole)userRole
                                         ownerId:(int64_t)ownerId
                                     ownerRole:(IMUserRole)ownerRole
                                        chat_t:(IMChatType)chat_t
{
    return [self.imStorage.conversationDao loadWithOwnerId:ownerId ownerRole:ownerRole otherUserOrGroupId:userOrGroupId userRole:userRole chatType:chat_t];
}

- (void)insertConversation:(Conversation *)conversation
{
    [self.imStorage.conversationDao insert:conversation];
}

- (void)resetConversationUnreadnum:(Conversation *)conversation
{
    ResetConversationUnreadNumOperation *operation = [[ResetConversationUnreadNumOperation alloc] init];
    operation.imService = self;
    operation.conversation = conversation;
    [self.writeOperationQueue addOperation:operation];
}

- (NSInteger)getAllConversationUnReadNumWithUser:(User *)owner
{
    return [self.imStorage sumOfAllConversationUnReadNumOwnerId:owner.userId userRole:owner.userRole];
}

- (BOOL)deleteConversation:(Conversation *)conversation owner:(User *)owner
{
    conversation.status = 1; //逻辑删除
    conversation.unReadNum = 0;
    [self.imStorage.conversationDao update:conversation];
    
    // 从 cache 中删除
//    [self.converastionsCache removeObject:conversation];
    
    return YES;
}

#pragma mark - cache
- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole
{
    if (userId == [self getSystemSecretary].userId && userRole == [self getSystemSecretary].userRole)
    {
        return [self getSystemSecretary];
    }
    
    if (userId == [self getCustomWaiter].userId && userRole == [self getCustomWaiter].userRole)
    {
        return [self getCustomWaiter];
    }
    
    User *owner = [IMEnvironment shareInstance].owner;
    if (owner.userId == userId && owner.userRole == owner.userRole) {
        return owner;
    }
    
    User *user = [self.imStorage.userDao loadUserAndMarkName:userId role:userRole owner:[IMEnvironment shareInstance].owner];
    if (!user)
    {
        user = [[User alloc] init];
        user.userId = userId;
        user.userRole = userRole;
        [self.imStorage.userDao insertOrUpdateUser:user];
        
        __WeakSelf__ weakSelf = self;
        [self.imEngine postGetUserInfo:userId role:userRole callback:^(User *result) {
            if (! weakSelf.bIsServiceActive) return ;
            if (! result) return;
            User *_user = [weakSelf getUser:userId role:userRole];
            [_user mergeValuesForKeysFromModel:result];
            [weakSelf.imStorage.userDao insertOrUpdateUser:_user];
            [weakSelf notifyUserInfoChanged:_user];
        }];
    }
    
    return user;
}

- (void)setUser:(id)user
{
    [self.imStorage.userDao insertOrUpdateUser:user];
}

- (Group *)getGroup:(int64_t)groupId
{
    User *owner = [IMEnvironment shareInstance].owner;
    Group *group = [self.imStorage.groupDao load:groupId];
    if (group)
    {
        GroupMember *member = [self.imStorage.groupMemberDao loadMember:owner.userId userRole:owner.userRole groupId:groupId];
        group.remarkName = member.remarkName;
        group.remarkHeader = member.remarkHeader;
        group.msgStatus = member.msgStatus;
        group.canLeave = member.canLeave;
        group.canDisband = member.canDisband;
        group.pushStatus = member.pushStatus;
    }
    else
    {
        group = [[Group alloc] init];
        group.groupId = groupId;
        __WeakSelf__ weakSelf = self;
        [self.imStorage.groupDao insertOrUpdate:group];
        
        [self.imEngine postGetGroupProfile:groupId callback:^(Group *result) {
            if (!weakSelf.bIsServiceActive) return ;
            if (! result) return;
            GroupMember *_groupMember = [[GroupMember alloc] init];
            _groupMember.userId = owner.userId;
            _groupMember.userRole = owner.userRole;
            _groupMember.groupId = groupId;
            _groupMember.msgStatus = group.msgStatus;
            _groupMember.canDisband = group.canDisband;
            _groupMember.canLeave = group.canLeave;
            _groupMember.remarkHeader = group.remarkHeader;
            _groupMember.remarkName = group.remarkName;
            _groupMember.pushStatus = group.pushStatus;
            
            [weakSelf.imStorage.groupMemberDao insertOrUpdate:_groupMember];
            [group mergeValuesForKeysFromModel:result];
            [weakSelf.imStorage.groupDao insertOrUpdate:group];
            [weakSelf notifyGroupProfileChanged:group];
        }];
    }
    return group;
}

#pragma mark - remark name
- (void)setRemarkName:(NSString *)remarkName
                 user:(User *)user
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postChangeRemarkName:remarkName userId:user.userId userRole:user.userRole callback:^(NSString *remarkName, NSString *remarkHeader, NSInteger errCode, NSString *errMsg) {
        
        if (! weakSelf.bIsServiceActive) return ;
        
        if (errCode == RESULT_CODE_SUCC)
        {
            user.remarkName = remarkName;
            user.remarkHeader = remarkHeader;
            [weakSelf.imStorage insertOrUpdateContactOwner:[IMEnvironment shareInstance].owner contact:user];
            callback(remarkName, errCode, errMsg);
        }
        else
        {
            callback(remarkName, errCode, errMsg);
        }
    }];
}

- (void)setRemarkName:(NSString *)remarkName
                group:(Group *)group
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback
{
}

- (BOOL)hasTeacher:(int64_t)teacherId ofUser:(User *)user
{
    User *contact = [[User alloc] init];
    contact.userId = teacherId;
    contact.userRole = eUserRole_Teacher;
    return [self.imStorage hasContactOwner:user contact:contact];
}

- (BOOL)hasInsitituion:(int64_t)institutionId ofUser:(User *)user
{
    User *contact = [[User alloc] init];
    contact.userId = institutionId;
    contact.userRole = eUserRole_Institution;
    return [self.imStorage hasContactOwner:user contact:contact];
}

- (GroupMember *)getGroupMember:(int64_t)groupId ofUser:(User *)user
{
    GroupMember *member = [self.imStorage.groupMemberDao loadMember:user.userId userRole:user.userRole groupId:groupId];
    return member;
}


- (NSArray *)getGroupsWithUser:(User *)user
{
    NSArray *groups = [self.imStorage.groupMemberDao loadAllGroups:user];
    return groups;
}

- (NSArray *)getTeacherContactsWithUser:(User *)user
{
    if (user.userRole == eUserRole_Teacher)
    {
        return [self.imStorage.teacherDao loadAll:user.userId role:eUserRole_Teacher];
    }
    else if (user.userRole == eUserRole_Student)
    {
        return [self.imStorage.studentDao loadAll:user.userId role:eUserRole_Teacher];
    }
    else if (user.userRole == eUserRole_Institution)
    {
        return [self.imStorage.institutionDao loadAll:user.userId role:eUserRole_Teacher];
    }
    return nil;
}

- (NSArray *)getStudentContactsWithUser:(User *)user
{
    if (user.userRole == eUserRole_Teacher)
    {
        return [self.imStorage.teacherDao loadAll:user.userId role:eUserRole_Student];
    }
    else if (user.userRole == eUserRole_Student)
    {
        return [self.imStorage.studentDao loadAll:user.userId role:eUserRole_Student];
    }
    else if (user.userRole == eUserRole_Institution)
    {
        return [self.imStorage.institutionDao loadAll:user.userId role:eUserRole_Student];
    }
    return nil;
}

- (NSArray *)getInstitutionContactsWithUser:(User *)user
{
    if (user.userRole == eUserRole_Teacher)
    {
        return [self.imStorage.teacherDao loadAll:user.userId role:eUserRole_Institution];
    }
    else if (user.userRole == eUserRole_Student)
    {
        return [self.imStorage.studentDao loadAll:user.userId role:eUserRole_Institution];
    }
    else if (user.userRole == eUserRole_Institution)
    {
        return [self.imStorage.institutionDao loadAll:user.userId role:eUserRole_Institution];
    }
    return nil;
}

- (void)addRecentContactId:(int64_t)userId
               contactRole:(IMUserRole)userRole
                  callback:(void (^)(BaseResponse *))callback
{
    [NetWorkTool hermesAddRecentContactId:userId role:userRole succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
       if (callback)
       {
           NSError *error;
           BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
           callback(result);
       }
    } failure:^(NSError *error, RequestParams *params) {
       if (callback)
           callback(nil);
    }];
}


#pragma mark -系统小秘书 & 客服
//系统小秘书
- (User *)getSystemSecretary
{
    if (self.systemSecretary == nil)
    {
        self.systemSecretary = [[User alloc] init];
        self.systemSecretary.userId = USER_SYSTEM_SECRETARY;
        self.systemSecretary.userRole = eUserRole_System;
        self.systemSecretary.name = @"系统小秘书";
    }
    return self.systemSecretary;
}
// 客服
- (User *)getCustomWaiter
{
    if (self.customeWaiter == nil)
    {
        self.customeWaiter = [[User alloc] init];
        self.customeWaiter.userId = USER_CUSTOM_WAITER;
        self.customeWaiter.userRole = eUserRole_Kefu;
        self.customeWaiter.name = @"客服";
    }
    return self.customeWaiter;
}

- (User *)getStranger
{
    if (self.stanger == nil) {
        self.stanger = [self.imStorage.userDao loadUser:USER_STRANGER role:eUserRole_Stanger];
        if (self.stanger == nil) {
            self.stanger = [[User alloc] init];
            self.stanger.userId = USER_STRANGER;
            self.stanger.userRole = eUserRole_Stanger;
            self.stanger.name = @"陌生人消息";
            [self.imStorage.userDao insertOrUpdateUser:self.stanger];
        }
    }
    return self.stanger;
}

- (User *)getNewFans
{
    if (self.nFans == nil) {
        self.nFans = [self.imStorage.userDao loadUser:USER_FRESH_FANS role:eUserRole_Fans];
        if (self.nFans == nil) {
            self.nFans = [[User alloc] init];
            self.nFans.userId = USER_FRESH_FANS;
            self.nFans.userRole = eUserRole_Fans;
            self.nFans.name = @"新粉丝";
        }
    }
    return self.nFans;
}

- (NSArray*)getMyNewFans
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllFans:user];
}

- (NSArray *)getMyFans
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllFans:user];
}

- (NSArray *)getMyAttentions
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllAttentions:user];
}

- (BOOL)getIsStanger:(User*)contact
{
    BOOL isStanger = NO;
    User *owner = [IMEnvironment shareInstance].owner;
    if (owner.userRole == eUserRole_Teacher) {
        
    }else if(owner.userRole == eUserRole_Student)
    {
        isStanger = [self.imStorage.socialContactsDao isStanger:contact withOwner:owner];
    }else if(owner.userRole == eUserRole_Institution)
    {
        
    }
    return isStanger;
}

- (void)addAttention:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postAddAttention:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        if(err == nil)
        {
            User *owner = [IMEnvironment shareInstance].owner;
            SetSocialFocusOperation *operation = [[SetSocialFocusOperation alloc] init];
            operation.imService = weakSelf;
            operation.owner = owner;
            operation.contact = contact;
            operation.bAddFocus = YES;
            
            [weakSelf.writeOperationQueue addOperation:operation];
        }
        if (callback)
            callback(err,result);
    }];
}

- (void)cancelAttention:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postCancelAttention:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        User *owner = [IMEnvironment shareInstance].owner;
        SetSocialFocusOperation *operation = [[SetSocialFocusOperation alloc] init];
        operation.imService = weakSelf;
        operation.owner = owner;
        operation.contact = contact;
        operation.bAddFocus = NO;
        
        [weakSelf.writeOperationQueue addOperation:operation];
        
        if (callback)
            callback(err,result);
    }];
}

- (void)addBlacklist:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postAddBlacklist:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        if (err == nil) {
            User *owner = [IMEnvironment shareInstance].owner;
            //[weakSelf.imStorage.socialContactsDao setContactTinyFoucs:eIMTinyFocus_None contact:contact owner:owner];
            //[weakSelf.imStorage.socialContactsDao setContactFocusType:NO contact:user owner:owner];
            [weakSelf.imStorage.socialContactsDao setContactBacklist:eIMBlackStatus_Active contact:contact owner:owner];
        }
        if (callback)
            callback(err,result);
    }];
}

- (void)cancelBlacklist:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postCancelBlacklist:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        if(err == nil)
        {
            User *owner = [IMEnvironment shareInstance].owner;
            [weakSelf.imStorage.socialContactsDao setContactBacklist:eIMBlackStatus_Normal contact:contact owner:owner];
        }
        if (callback)
            callback(err,result);
    }];
}

- (BJIMAbstractEngine *)imEngine
{
    if (_imEngine == nil)
    {
        //默认使用 Socket Engine.
        _imEngine = [[BJIMSocketEngine alloc] init];
    }
    return _imEngine;
}

- (BJIMStorage *)imStorage
{
    if (_imStorage == nil)
    {
        _imStorage = [[BJIMStorage alloc] init];
    }
    return _imStorage;
}

- (NSOperationQueue *)readOperationQueue
{
    if (_readOperationQueue == nil)
    {
        _readOperationQueue = [[NSOperationQueue alloc] init];
        [_readOperationQueue setMaxConcurrentOperationCount:1];
    }
    return _readOperationQueue;
}

- (NSOperationQueue *)writeOperationQueue
{
    if (_writeOperationQueue == nil)
    {
        _writeOperationQueue = [[NSOperationQueue alloc] init];
        //DB 写操作只能顺序执行
        [_writeOperationQueue setMaxConcurrentOperationCount:1];
    }
    return _writeOperationQueue;
}

- (NSOperationQueue *)sendMessageOperationQueue
{
    if (_sendMessageOperationQueue == nil) {
        _sendMessageOperationQueue = [[NSOperationQueue alloc] init];
        [_sendMessageOperationQueue setMaxConcurrentOperationCount:1];
    }
    return _sendMessageOperationQueue;
}

- (NSOperationQueue *)receiveMessageOperationQueue
{
    if (_receiveMessageOperationQueue == nil) {
        _receiveMessageOperationQueue = [[NSOperationQueue alloc] init];
        [_receiveMessageOperationQueue setMaxConcurrentOperationCount:1];
    }
    return _receiveMessageOperationQueue;
}

- (NSOperationQueue *)syncContactsOperationQueue
{
    if (_syncContactsOperationQueue == nil) {
        _syncContactsOperationQueue = [[NSOperationQueue alloc] init];
        [_syncContactsOperationQueue setMaxConcurrentOperationCount:1];
    }
    return _syncContactsOperationQueue;

}

#pragma mark - application call back
- (void)applicationEnterForeground
{
    if (self.bIsServiceActive)
        [self.imEngine start];
}

- (void)applicationEnterBackground
{
    [self.imEngine stop];
}

#pragma mark - add Delegates
- (void)addConversationChangedDelegate:(id<IMConversationChangedDelegate>)delegate
{
    if (self.conversationDelegates == nil)
    {
        self.conversationDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.conversationDelegates addObject:delegate];
}

- (void)notifyConversationChanged
{
    NSEnumerator *enumerator = [self.conversationDelegates objectEnumerator];
    id<IMConversationChangedDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didConversationDidChanged)])
             [delegate didConversationDidChanged];
    }
}

- (void)addReceiveNewMessageDelegate:(id<IMReceiveNewMessageDelegate>)delegate
{
    if (self.receiveNewMessageDelegates == nil)
    {
        self.receiveNewMessageDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.receiveNewMessageDelegates addObject:delegate];
}
- (void)notifyReceiveNewMessages:(NSArray *)newMessages
{
    NSEnumerator *enumerator = [self.receiveNewMessageDelegates objectEnumerator];
    id<IMReceiveNewMessageDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didReceiveNewMessages:)])
            [delegate didReceiveNewMessages:newMessages];
    }
}

- (void)addDeliveryMessageDelegate:(id<IMDeliveredMessageDelegate>)delegate
{
    if (self.deliveredMessageDelegates == nil)
    {
        self.deliveredMessageDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.deliveredMessageDelegates addObject:delegate];
}

- (void)notifyWillDeliveryMessage:(IMMessage *)message
{
    NSEnumerator *enumerator = [self.deliveredMessageDelegates objectEnumerator];
    id<IMDeliveredMessageDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(willDeliveryMessage:)])
            [delegate willDeliveryMessage:message];
    }
}

- (void)notifyDeliverMessage:(IMMessage *)message
                   errorCode:(NSInteger)errorCode
                       error:(NSString *)errorMsg
{
    NSEnumerator *enumerator = [self.deliveredMessageDelegates objectEnumerator];
    id<IMDeliveredMessageDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didDeliveredMessage:errorCode:error:)])
            [delegate didDeliveredMessage:message errorCode:errorCode error:errorMsg];
    }
}

- (void)addCmdMessageDelegate:(id<IMCmdMessageDelegate>)delegate
{
    if (self.cmdMessageDelegates == nil)
    {
        self.cmdMessageDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.cmdMessageDelegates addObject:delegate];
}

- (void)notifyCmdMessages:(NSArray *)cmdMessages
{
    NSEnumerator *enumerator = [self.cmdMessageDelegates objectEnumerator];
    id<IMCmdMessageDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didReceiveCommand:)])
            [delegate didReceiveCommand:cmdMessages];
    }
}

- (void)addContactChangedDelegate:(id<IMContactsChangedDelegate>)delegate
{
    if (self.contactChangedDelegates == nil)
    {
        self.contactChangedDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.contactChangedDelegates addObject:delegate];
}
- (void)notifyContactChanged
{
    NSEnumerator *enumerator = [self.contactChangedDelegates objectEnumerator];
    id<IMContactsChangedDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didMyContactsChanged)])
            [delegate didMyContactsChanged];
    }
}

- (void)addLoadMoreMessagesDelegate:(id<IMLoadMessageDelegate>)delegate
{
    if (self.loadMoreMessagesDelegates == nil)
    {
        self.loadMoreMessagesDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.loadMoreMessagesDelegates addObject:delegate];
}

- (void)notifyPreLoadMessages:(NSArray *)messages conversation:(Conversation *)conversation
{
    NSEnumerator *enumerator = [self.loadMoreMessagesDelegates objectEnumerator];
    id<IMLoadMessageDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didPreLoadMessages:conversation:)])
            [delegate didPreLoadMessages:messages conversation:conversation];
    }
}

- (void)notifyLoadMoreMessages:(NSArray *)messages conversation:(Conversation *)conversation hasMore:(BOOL)hasMore
{
    NSEnumerator *enumerator = [self.loadMoreMessagesDelegates objectEnumerator];
    id<IMLoadMessageDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didLoadMessages:conversation:hasMore:)])
            [delegate didLoadMessages:messages conversation:conversation hasMore:hasMore];
    }
}

- (void)addRecentContactsDelegate:(id<IMRecentContactsDelegate>)delegate
{
    if (self.recentContactsDelegates == nil)
    {
        self.recentContactsDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.recentContactsDelegates addObject:delegate];
}

- (void)notifyRecentContactsChanged:(NSArray *)contacts
{
    NSEnumerator *enumerator = [self.recentContactsDelegates objectEnumerator];
    id<IMRecentContactsDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didLoadRecentContacts:)])
            [delegate didLoadRecentContacts:contacts];
    }
}

- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate
{
    if (self.userInfoDelegates == nil)
    {
        self.userInfoDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.userInfoDelegates addObject:delegate];

}

- (void)notifyUserInfoChanged:(User *)user
{
    NSEnumerator *enumerator = [self.userInfoDelegates objectEnumerator];
    id<IMUserInfoChangedDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didUserInfoChanged:)])
            [delegate didUserInfoChanged:user];
    }
}

- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate
{
    if (self.groupInfoDelegates == nil)
    {
        self.groupInfoDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.groupInfoDelegates addObject:delegate];
}

- (void)notifyGroupProfileChanged:(Group *)group
{
    NSEnumerator *enumerator = [self.groupInfoDelegates objectEnumerator];
    id<IMGroupProfileChangedDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didGroupProfileChanged:)])
            [delegate didGroupProfileChanged:group];
    }
}

- (void)addDisconnectionDelegate:(id<IMDisconnectionDelegate>)delegate
{
    if (self.disconnectionStateDelegates == nil)
    {
        self.disconnectionStateDelegates = [NSHashTable weakObjectsHashTable];
    }
    [self.disconnectionStateDelegates addObject:delegate];
}

- (void)notifyErrorCode:(IMErrorType)code msg:(NSString *)msg
{
    NSEnumerator *enumerator = [self.disconnectionStateDelegates objectEnumerator];
    id<IMDisconnectionDelegate> delegate = nil;
    while (delegate = [enumerator nextObject]) {
        if ([delegate respondsToSelector:@selector(didDisconnectionServer:errMsg:)])
            [delegate didDisconnectionServer:code errMsg:msg];
    }
}

- (void)addLoginLogoutDelegate:(id<IMLoginLogoutDelegate>)delegate
{
    if (self.imLoginLogoutDelegates == nil)
    {
        self.imLoginLogoutDelegates = [NSHashTable weakObjectsHashTable];
    }
    [self.imLoginLogoutDelegates addObject:delegate];
}

- (void)notifyIMLoginFinish
{
    NSEnumerator *enumerator = [self.imLoginLogoutDelegates objectEnumerator];
    id<IMLoginLogoutDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didIMManagerLoginFinish)])
        {
            if ([delegate respondsToSelector:@selector(didIMManagerLoginFinish)])
                [delegate didIMManagerLoginFinish];
        }
    }
}

- (void)notifyIMLogoutFinish
{
    NSEnumerator *enumerator = [self.imLoginLogoutDelegates objectEnumerator];
    id<IMLoginLogoutDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didIMManagerLogoutFinish)])
        {
            [delegate didIMManagerLogoutFinish];
        }
    }
}

- (void)addUnReadNumChangedDelegate:(id<IMUnReadNumChangedDelegate>)delegate
{
    if (self.imUnReadNumChangedDelegates == nil)
    {
        self.imUnReadNumChangedDelegates = [NSHashTable weakObjectsHashTable];
    }
    [self.imUnReadNumChangedDelegates addObject:delegate];
}

- (void)notifyUnReadNumChanged:(NSInteger)unReadNum
{
    NSEnumerator *enumerator = [self.imUnReadNumChangedDelegates objectEnumerator];
    id<IMUnReadNumChangedDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didUnReadNumChanged:)])
        {
            [delegate didUnReadNumChanged:unReadNum];
        }
    }
}

@end
