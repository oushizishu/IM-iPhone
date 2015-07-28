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
#import  "NSDictionary+MTLMappingAdditions.h"
#import "IMEnvironment.h"
#import "BJIMStorage.h"
#import "IMMessage+DB.h"


#import "SendMsgOperation.h"
#import "HandlePostMessageSuccOperation.h"
#import "PrePollingOperation.h"
#import "HandlePollingResultOperation.h"
#import "LoadMoreMessagesOperation.h"
#import "HandleGetMsgOperation.h"
#import "SyncContactOperation.h"

@interface BJIMService()<IMEnginePostMessageDelegate,IMEngineSynContactDelegate, IMEnginePollingDelegate,
    IMEngineGetMessageDelegate>

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL bIsServiceActive;

@property (nonatomic, strong) NSHashTable *conversationDelegates;
@property (nonatomic, strong) NSHashTable *receiveNewMessageDelegates;
@property (nonatomic, strong) NSHashTable *deliveredMessageDelegates;
@property (nonatomic, strong) NSHashTable *cmdMessageDelegates;
@property (nonatomic, strong) NSHashTable *contactChangedDelegates;
@property (nonatomic, strong) NSHashTable *loadMoreMessagesDelegates;

@property (nonatomic, strong) NSMutableArray *usersCache;
@property (nonatomic, strong) NSMutableArray *groupsCache;

@end

@implementation BJIMService
@synthesize imEngine=_imEngine;
@synthesize imStorage=_imStorage;

- (void)startServiceWithOwner:(User *)owner
{
    self.bIsServiceActive = YES;
    self.imEngine.pollingDelegate = self;
    self.imEngine.postMessageDelegate = self;
    self.imEngine.getMsgDelegate = self;
    self.imEngine.synContactDelegate = self;
    
    [self.imEngine start];
    
    [self.imEngine syncConfig];
    [self.imEngine syncContacts];
}

- (void)stopService
{
    [self.operationQueue cancelAllOperations];
    self.bIsServiceActive = NO;
    
    [self.imEngine stop];
    
    self.imEngine.pollingDelegate = nil;
    self.imEngine.postMessageDelegate = nil;
    self.imEngine.getMsgDelegate = nil;
    self.imEngine.synContactDelegate = nil;
    
    [self.usersCache removeAllObjects];
    [self.groupsCache removeAllObjects];
    
}

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message
{
    message.status = eMessageStatus_Sending;
    message.imService = self;
    SendMsgOperation *operation = [[SendMsgOperation alloc] init];
    operation.message = message;
    operation.imService = self;
    [self.operationQueue addOperation:operation];
    
    [self notifyWillDeliveryMessage:message];
}

- (void)retryMessage:(IMMessage *)message
{
    [self notifyWillDeliveryMessage:message];
}

- (NSArray *)loadMessages:(Conversation *)conversation minMsgId:(double_t)minMsgId
{
    if (minMsgId <= 0)
    {
    
        if (conversation.chat_t == eChatType_Chat)
        {
            NSArray *array = [self.imStorage loadChatMessagesInConversation:conversation.rowid];
            return array;
        }
        else
        {
            Group *_chatToGroup = [self.imStorage queryGroupWithGroupId:conversation.toId];
            NSArray *array = [self.imStorage loadGroupChatMessages:_chatToGroup inConversation:conversation.rowid];
            return array;
        }
    }
    
    LoadMoreMessagesOperation *operation = [[LoadMoreMessagesOperation alloc] init];
    
    operation.minMsgId = minMsgId;
    operation.imService = self;
    operation.conversation = conversation;
    [self.operationQueue addOperation:operation];
    return nil;
}

#pragma mark - Post Message Delegate
- (void)onPostMessageSucc:(IMMessage *)message result:(SendMsgModel *)model
{
    if (!self.bIsServiceActive) return;
    
    HandlePostMessageSuccOperation *operation = [[HandlePostMessageSuccOperation alloc] init];
    operation.imService = self;
    operation.message = message;
    operation.model = model;
    
    [self.operationQueue addOperation:operation];
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
    [self.operationQueue addOperation:operation];
}

- (void)onPollingFinish:(PollingResultModel *)model
{
    if (! self.bIsServiceActive) return;
    
    HandlePollingResultOperation *operation = [[HandlePollingResultOperation alloc] init];
    operation.imService = self;
    operation.model = model;
    [self.operationQueue addOperation:operation];
}

#pragma mark - get Msg Delegate
- (void)onGetMsgSucc:(NSInteger)conversationId minMsgId:(double_t)minMsgId result:(PollingResultModel *)model
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.conversationId = conversationId;
    operation.model = model;
    operation.minMsgId = minMsgId;
    [self.operationQueue addOperation:operation];
}

- (void)onGetMsgFail:(NSInteger)conversationId minMsgId:(double_t)minMsgId
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.conversationId = conversationId;
    operation.minMsgId = minMsgId;
    
    [self.operationQueue addOperation:operation];
}

#pragma mark syncContact 
- (void)didSyncContacts:(MyContactsModel *)model
{
    
    if (! self.bIsServiceActive) return;

    SyncContactOperation *operation = [[SyncContactOperation alloc]init];
    operation.imService = self;
    operation.model = model;
    [self.operationQueue addOperation:operation];
}


#pragma mark - Setter & Getter
- (NSArray *)getAllConversationWithOwner:(User *)owner
{
    NSArray *list = [self.imStorage queryAllConversationOwnerId:owner.userId userRole:owner.userRole];
    
    __WeakSelf__ weakSelf = self;
    [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Conversation *conversation = (Conversation *)obj;
        conversation.imService = weakSelf;
    }];
    return list;
}

- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole
{
    for (NSInteger index = 0; index < [self.usersCache count]; ++ index)
    {
        User *user = [self.usersCache objectAtIndex:index];
        if (user.userId == userId && user.userRole == userRole)
        {
            return user;
        }
    }
    
    User *user = [self.imStorage queryUser:userId userRole:userRole];
    if (user) {
        [self.usersCache addObject:user];
    }
    
    return user;
}

- (Group *)getGroup:(int64_t)groupId
{
    for (NSInteger index = 0; index < [self.groupsCache count]; ++ index) {
        Group *group = [self.groupsCache objectAtIndex:index];
        if (group.groupId == groupId) {
            return group;
        }
    }
    
    Group *group = [self.imStorage queryGroupWithGroupId:groupId];
    if (group)
    {
        [self.groupsCache addObject:group];
    }
    return group;
}

- (Conversation *)getConversationUserOrGroupId:(int64_t)userOrGroupId
                                      userRole:(IMUserRole)userRole
                                         owner:(User *)owner
                                        chat_t:(IMChatType)chat_t
{
    Conversation *conversation = [self.imStorage queryConversation:owner.userId ownerRole:owner.userRole otherUserOrGroupId:userOrGroupId userRole:userRole chatType:chat_t];
    conversation.imService = self;
    return conversation;
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

- (NSOperationQueue *)operationQueue
{
    if (_operationQueue == nil)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:3];
    }
    return _operationQueue;
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
        self.conversationDelegates = [[NSHashTable alloc] init];
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
        self.receiveNewMessageDelegates = [[NSHashTable alloc] init];
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
        self.deliveredMessageDelegates = [[NSHashTable alloc] init];
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
        self.cmdMessageDelegates = [[NSHashTable alloc] init];
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
        self.contactChangedDelegates = [[NSHashTable alloc] init];
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
        self.loadMoreMessagesDelegates = [[NSHashTable alloc] init];
    }
    
    [self.loadMoreMessagesDelegates addObject:delegate];
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
@end
