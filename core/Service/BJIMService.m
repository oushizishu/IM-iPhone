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

@interface BJIMService()<IMEnginePostMessageDelegate,IMEngineSynContactDelegate, IMEnginePollingDelegate,
    IMEngineGetMessageDelegate, IMEngineSyncConfigDelegate>


@property (nonatomic, strong) NSHashTable *conversationDelegates;
@property (nonatomic, strong) NSHashTable *receiveNewMessageDelegates;
@property (nonatomic, strong) NSHashTable *deliveredMessageDelegates;
@property (nonatomic, strong) NSHashTable *cmdMessageDelegates;
@property (nonatomic, strong) NSHashTable *contactChangedDelegates;
@property (nonatomic, strong) NSHashTable *loadMoreMessagesDelegates;
@property (nonatomic, strong) NSHashTable *recentContactsDelegates;
@property (nonatomic, strong) NSHashTable *userInfoDelegates;
@property (nonatomic, strong) NSHashTable *groupInfoDelegates;

@property (nonatomic, strong) NSMutableArray *usersCache;
@property (nonatomic, strong) NSMutableArray *groupsCache;
@property (nonatomic, strong) NSMutableArray *converastionsCache;

@property (nonatomic, strong) User *systemSecretary;
@property (nonatomic, strong) User *customeWaiter;
@property (nonatomic, strong, readonly) NSOperationQueue *readOperationQueue; //DB 读操作线程

@end

@implementation BJIMService
@synthesize imEngine=_imEngine;
@synthesize imStorage=_imStorage;
@synthesize readOperationQueue=_readOperationQueue;
@synthesize writeOperationQueue=_writeOperationQueue;

- (void)startServiceWithOwner:(User *)owner
{
    self.bIsServiceActive = YES;
    self.imEngine.pollingDelegate = self;
    self.imEngine.postMessageDelegate = self;
    self.imEngine.getMsgDelegate = self;
    self.imEngine.synContactDelegate = self;
    self.imEngine.syncConfigDelegate = self;
    
    [self.imStorage insertOrUpdateUser:owner];
    
    [self.imEngine start];
    
    [self.imEngine syncConfig];
    [self.imEngine syncContacts];
}

- (void)stopService
{
    [self.readOperationQueue cancelAllOperations];
    [self.writeOperationQueue cancelAllOperations];
    self.bIsServiceActive = NO;
    
    [self.imEngine stop];
    
    self.imEngine.pollingDelegate = nil;
    self.imEngine.postMessageDelegate = nil;
    self.imEngine.getMsgDelegate = nil;
    self.imEngine.synContactDelegate = nil;
    self.imEngine.syncConfigDelegate = nil;
    
    [self.usersCache removeAllObjects];
    [self.groupsCache removeAllObjects];
    [self.converastionsCache removeAllObjects];
    
    self.systemSecretary = nil;
    self.customeWaiter = nil;
}

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message
{
    message.status = eMessageStatus_Sending;
    message.imService = self;
    SendMsgOperation *operation = [[SendMsgOperation alloc] init];
    operation.message = message;
    operation.imService = self;
//    [self.operationQueue addOperation:operation];
    [self.readOperationQueue addOperation:operation]; //可以放在读的队列中
    
    [self notifyWillDeliveryMessage:message];
}

- (void)retryMessage:(IMMessage *)message
{
    message.status = eMessageStatus_Sending;
    message.imService = self;
    RetryMessageOperation *operation = [[RetryMessageOperation alloc] init];
    operation.message = message;
    operation.imService = self;
//    [self.operationQueue addOperation:operation];
    [self.readOperationQueue addOperation:operation]; //可以放在读的队列中
    
    [self notifyWillDeliveryMessage:message];
}

- (void)loadMessages:(Conversation *)conversation minMsgId:(NSString *)minMsgId
{
    LoadMoreMessagesOperation *operation = [[LoadMoreMessagesOperation alloc] init];
    
    operation.minMsgId = minMsgId;
    operation.imService = self;
    operation.conversation = conversation;
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
    
//    [self.operationQueue addOperation:operation];
    [self.writeOperationQueue addOperation:operation];
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
    [self.imStorage updateMessage:message];
    [self.imEngine postMessage:message];
}

- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error
{
    if (! self.bIsServiceActive) return;
    
    message.status = eMessageStatus_Send_Fail;
    [self.imStorage updateMessage:message];
    
    [self notifyDeliverMessage:message errorCode:error.code error:[error.userInfo valueForKey:@"msg"]];
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
    
    HandlePollingResultOperation *operation = [[HandlePollingResultOperation alloc] init];
    operation.imService = self;
    operation.model = model;
//    [self.operationQueue addOperation:operation];
    [self.writeOperationQueue addOperation:operation];
}

#pragma mark - get Msg Delegate
- (void)onGetMsgSucc:(NSInteger)conversationId minMsgId:(NSString *)minMsgId newEndMessageId:(NSString *)newEndMessageId result:(PollingResultModel *)model
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.conversationId = conversationId;
    operation.model = model;
    operation.minMsgId = minMsgId;
    operation.endMessageId = newEndMessageId;
//    [self.operationQueue addOperation:operation];
    [self.writeOperationQueue addOperation:operation];
}

- (void)onGetMsgFail:(NSInteger)conversationId minMsgId:(NSString *)minMsgId
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.conversationId = conversationId;
    operation.minMsgId = minMsgId;
    
//    [self.operationQueue addOperation:operation];
    [self.writeOperationQueue addOperation:operation];
}

#pragma mark syncContact 
- (void)didSyncContacts:(MyContactsModel *)model
{
    if (! self.bIsServiceActive) return;

    SyncContactOperation *operation = [[SyncContactOperation alloc]init];
    operation.imService = self;
    operation.model = model;
//    [self.operationQueue addOperation:operation];
    [self.writeOperationQueue addOperation:operation];
}

#pragma mark - syncConfigDelegate
- (void)onSyncConfig:(SyncConfigModel *)model
{
    User *system = [self getSystemSecretary];
    system.userId = model.systemSecretary.number;
    system.userRole = model.systemSecretary.role;
    
    User *waiter = [self getCustomWaiter];
    waiter.userId = model.customWaiter.number;
    waiter.userRole = model.customWaiter.role;
}


#pragma mark - Setter & Getter
#pragma mark -- conversation
- (NSArray *)getAllConversationWithOwner:(User *)owner
{
    if ([self.converastionsCache count] == 0)
    {
        NSArray *list = [self getAllConversationFromDBWithOwner:owner];
        [self.converastionsCache addObjectsFromArray:list];
    }
    
    [self.converastionsCache sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Conversation *con1 = (Conversation *)obj1;
        Conversation *con2 = (Conversation *)obj2;
        return [con1.lastMessageId compare:con2.lastMessageId];
    }];

    return self.converastionsCache;
}

- (NSArray *)getAllConversationFromDBWithOwner:(User *)owner
{
    NSArray *list = [self.imStorage queryAllConversationOwnerId:owner.userId userRole:owner.userRole];
    
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
    Conversation *conversation = nil;

    for (NSInteger index = 0; index < self.converastionsCache.count; ++ index)
    {
        Conversation *_conversation = [self.converastionsCache objectAtIndex:index];
        if (_conversation.ownerId == ownerId &&
            _conversation.ownerRole == ownerRole &&
            _conversation.toId == userOrGroupId &&
            _conversation.toRole == userRole &&
            _conversation.chat_t == chat_t)
        {
            conversation = _conversation;
            break;
        }
    }
    
    if (conversation == nil)
    {
        conversation = [self getConversationFromDBUserOrGroupId:userOrGroupId userRole:userRole ownerId:ownerId ownerRole:ownerRole chat_t:chat_t];
        [self.converastionsCache addObject:conversation];
    }
    return conversation;
}

- (Conversation *)getConversationFromDBUserOrGroupId:(int64_t)userOrGroupId
                                      userRole:(IMUserRole)userRole
                                         ownerId:(int64_t)ownerId
                                           ownerRole:(IMUserRole)ownerRole
                                        chat_t:(IMChatType)chat_t
{
    Conversation *conversation = [self.imStorage queryConversation:ownerId ownerRole:ownerRole otherUserOrGroupId:userOrGroupId userRole:userRole chatType:chat_t];
    
    conversation.imService = self;
    return conversation;
}

- (void)insertConversation:(Conversation *)conversation
{
    [self.converastionsCache addObject:conversation];
    [self.imStorage insertConversation:conversation];
}

- (NSInteger)getAllConversationUnReadNumWithUser:(User *)owner
{
//    return [self.imStorage sumOfAllConversationUnReadNumOwnerId:owner.userId userRole:owner.userRole];
    NSInteger unreadNum = 0;
    for (NSInteger index = 0; index < self.converastionsCache.count; ++ index)
    {
        unreadNum += [[self.converastionsCache objectAtIndex:index] unReadNum];
    }

    return unreadNum;
}

- (BOOL)deleteConversation:(Conversation *)conversation owner:(User *)owner
{
    conversation.status = 1; //逻辑删除
    conversation.unReadNum = 0;
    [self.imStorage updateConversation:conversation];
    
    // 从 cache 中删除
    [self.converastionsCache removeObject:conversation];
    
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
    
    for (NSInteger index = 0; index < [self.usersCache count]; ++ index)
    {
        User *user = [self.usersCache objectAtIndex:index];
        if (user.userId == userId && user.userRole == userRole)
        {
            return user;
        }
    }
    
    User *user = [self.imStorage queryUser:userId userRole:userRole];
    if (user)
    {
        [self.imStorage queryAndSetUserRemark:user owner:[IMEnvironment shareInstance].owner];
        [self.usersCache addObject:user];
    }
    else
    {
        user = [[User alloc] init];
        user.userId = userId;
        user.userRole = userRole;
        [self.usersCache addObject:user];
        __WeakSelf__ weakSelf = self;
        [self.imEngine postGetUserInfo:userId role:userRole callback:^(User *result) {
            if (! weakSelf.bIsServiceActive) return ;
            if (! result) return;
            User *_user = [weakSelf getUser:userId role:userRole];
            [_user mergeValuesForKeysFromModel:result];
            [weakSelf.imStorage insertOrUpdateUser:_user];
            [weakSelf notifyUserInfoChanged:_user];
        }];
    }
    
    return user;
}

- (void)updateCacheUser:(User *)user
{
    for (NSInteger index = 0; index < [self.usersCache count]; ++ index)
    {
        User *_user = [self.usersCache objectAtIndex:index];
        if (_user.userId == user.userId && _user.userRole == user.userRole)
        {
            _user.name = user.name;
            _user.avatar = user.avatar;
            return;
        }
    }
}

- (User *)getUserFromCache:(int64_t)userId role:(IMUserRole)userRole
{
    for (NSInteger index = 0; index < [self.usersCache count]; ++ index)
    {
        User *_user = [self.usersCache objectAtIndex:index];
        if (_user.userId == userId && _user.userRole == userRole)
        {
            return _user;
        }
    }
    return nil;
}

- (Group *)getGroupFromCache:(int64_t)groupId
{
    for (NSInteger index = 0; index < [self.groupsCache count]; ++ index) {
        Group *_group = [self.groupsCache objectAtIndex:index];
        if (_group.groupId == groupId) {
            return _group;
        }
    }
    return nil;
}

- (void)updateCacheGroup:(Group *)group
{
    for (NSInteger index = 0; index < [self.groupsCache count]; ++ index) {
        Group *_group = [self.groupsCache objectAtIndex:index];
        if (_group.groupId == group.groupId) {
           
            [_group mergeValuesForKeysFromModel:group];
            
            return;
        }
    }
}

- (Group *)getGroup:(int64_t)groupId
{
    for (NSInteger index = 0; index < [self.groupsCache count]; ++ index) {
        Group *group = [self.groupsCache objectAtIndex:index];
        if (group.groupId == groupId) {
            return group;
        }
    }
    
    User *owner = [IMEnvironment shareInstance].owner;
    Group *group = [self.imStorage queryGroupWithGroupId:groupId];
    if (group)
    {
        GroupMember *member = [self.imStorage queryGroupMemberWithGroupId:groupId userId:owner.userId userRole:owner.userRole];
        group.remarkName = member.remarkName;
        group.remarkHeader = member.remarkHeader;
        group.msgStatus = member.msgStatus;
        group.canLeave = member.canLeave;
        group.canDisband = member.canDisband;
        
        [self.groupsCache addObject:group];
    }
    else
    {
        group = [[Group alloc] init];
        group.groupId = groupId;
        [self.groupsCache addObject:group];
        __WeakSelf__ weakSelf = self;
        [self.imEngine postGetGroupProfile:groupId callback:^(Group *result) {
            if (!weakSelf.bIsServiceActive) return ;
            if (! result) return;
            Group *_group = [weakSelf getGroup:groupId];
            GroupMember *_groupMember = [[GroupMember alloc] init];
            _groupMember.userId = owner.userId;
            _groupMember.userRole = owner.userRole;
            _groupMember.groupId = groupId;
            _groupMember.msgStatus = group.msgStatus;
            _groupMember.canDisband = group.canDisband;
            _groupMember.canLeave = group.canLeave;
            _groupMember.remarkHeader = group.remarkHeader;
            _groupMember.remarkName = group.remarkName;
            [weakSelf.imStorage insertOrUpdateGroupMember:_groupMember];
            [_group mergeValuesForKeysFromModel:result];
            [weakSelf.imStorage insertOrUpdateGroup:_group];
            [weakSelf notifyGroupProfileChanged:_group];
        }];
    }
    return group;
}

- (void)insertUserToCache:(User *)user
{
    [self.usersCache addObject:user];
}

- (void)insertGroupToCache:(Group *)group
{
    [self.groupsCache addObject:group];
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

- (GroupMember *)getGroupMember:(int64_t)groupId ofUser:(User *)user
{
    GroupMember *member = [self.imStorage queryGroupMemberWithGroupId:groupId userId:user.userId userRole:user.userRole];
    return member;
}

- (void)setUser:(User *)user
{
    [self.imStorage insertOrUpdateUser:user];
}

- (NSArray *)getGroupsWithUser:(User *)user
{
    NSArray *groups = [self.imStorage queryGroupsWithUser:user];
    NSMutableArray *list = [NSMutableArray array];
    
    for (NSInteger index = 0; index < [groups count]; ++ index) {
        Group *group = [groups objectAtIndex:index];
        Group *_group = [self getGroupFromCache:group.groupId];
        GroupMember *member = [self.imStorage queryGroupMemberWithGroupId:_group.groupId userId:user.userId userRole:user.userRole];
        
        if (_group)
        {
            [_group mergeValuesForKeysFromModel:group];
        }
        else
        {
            _group = group;
            [self.groupsCache addObject:group];
        }
        
        if (member) {
            _group.remarkName = member.remarkName;
            _group.remarkHeader = member.remarkHeader;
            _group.msgStatus = member.msgStatus;
            _group.canLeave = member.canLeave;
            _group.canDisband = member.canDisband;
        }
        
        [list addObject:_group];
    }
    return list;
}

- (NSArray *)getTeacherContactsWithUser:(User *)user
{
    NSArray *array = [self.imStorage queryTeacherContactWithUserId:user.userId userRole:user.userRole];
    NSMutableArray *list = [NSMutableArray array];
    
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        User *user = [array objectAtIndex:index];
        User *_user = [self getUserFromCache:user.userId role:user.userRole];
        if (_user)
        {
            [_user mergeValuesForKeysFromModel:user];
            [list addObject:_user];
        }
        else
        {
            [self.usersCache addObject:user];
            [list addObject:user];
        }
    }

    return list;
}

- (NSArray *)getStudentContactsWithUser:(User *)user
{
    NSArray *array = [self.imStorage queryStudentContactWithUserId:user.userId userRole:user.userRole];
    NSMutableArray *list = [NSMutableArray array];
    
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        User *user = [array objectAtIndex:index];
        User *_user = [self getUserFromCache:user.userId role:user.userRole];
        if (_user)
        {
            [_user mergeValuesForKeysFromModel:user];
            [list addObject:_user];
        }
        else
        {
            [self.usersCache addObject:user];
            [list addObject:user];
        }
    }
    
    return list;
}

- (NSArray *)getInstitutionContactsWithUser:(User *)user
{
    NSArray *array = [self.imStorage queryInstitutionContactWithUserId:user.userId userRole:user.userRole];
    NSMutableArray *list = [NSMutableArray array];
    
    for (NSInteger index = 0; index < [array count]; ++ index)
    {
        User *user = [array objectAtIndex:index];
        User *_user = [self getUserFromCache:user.userId role:user.userRole];
        if (_user)
        {
            [_user mergeValuesForKeysFromModel:user];
            [list addObject:_user];
        }
        else
        {
            [self.usersCache addObject:user];
            [list addObject:user];
        }
    }
    
    return list;
}


#pragma mark -系统小秘书 & 客服
//系统小秘书
- (User *)getSystemSecretary
{
    if (self.systemSecretary == nil)
    {
        self.systemSecretary = [[User alloc] init];
        self.systemSecretary.userId = 100000100;
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
        self.customeWaiter.userId = 100000110;
        self.customeWaiter.userRole = eUserRole_Kefu;
        self.customeWaiter.name = @"客服";
    }
    return self.customeWaiter;
}

- (BJIMEngine *)imEngine
{
    if (_imEngine == nil)
    {
        _imEngine = [[BJIMEngine alloc] init];
        _imEngine.synContactDelegate = self;
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
        [_readOperationQueue setMaxConcurrentOperationCount:3];
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

- (NSMutableArray *)usersCache
{
    if (_usersCache == nil)
    {
        _usersCache = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return _usersCache;
}

- (NSMutableArray *)groupsCache
{
    if (_groupsCache == nil)
    {
        _groupsCache = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return _groupsCache;
}

- (NSMutableArray *)converastionsCache
{
    if (_converastionsCache == nil)
    {
        _converastionsCache = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return _converastionsCache;
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
        [delegate didPreLoadMessages:messages conversation:conversation];
    }
}

- (void)notifyLoadMoreMessages:(NSArray *)messages conversation:(Conversation *)conversation hasMore:(BOOL)hasMore
{
    NSEnumerator *enumerator = [self.loadMoreMessagesDelegates objectEnumerator];
    id<IMLoadMessageDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
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
        [delegate didGroupProfileChanged:group];
    }
}


@end
