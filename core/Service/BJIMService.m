//
//  BJIMService.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "BJIMService.h"
#import "SendMsgOperation.h"
#import <BJHL-Common-iOS-SDK/BJCommonDefines.h>
#import "Conversation+DB.h"
#import  "NSDictionary+MTLMappingAdditions.h"
#import "IMEnvironment.h"
#import "ContactFactory.h"
#import "BJIMStorage.h"
@interface BJIMService()<IMEnginePostMessageDelegate,IMEngineSynContactDelegate>

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL bIsServiceActive;
@property (nonatomic ,strong) BJIMStorage *storage;

@property (nonatomic, strong) NSHashTable *conversationDelegates;
@property (nonatomic, strong) NSHashTable *receiveNewMessageDelegates;
@property (nonatomic, strong) NSHashTable *deliveredMessageDelegates;
@property (nonatomic, strong) NSHashTable *cmdMessageDelegates;
@property (nonatomic, strong) NSHashTable *contactChangedDelegates;
@property (nonatomic, strong) NSHashTable *loadMoreMessagesDelegates;

@end

@implementation BJIMService
@synthesize imEngine=_imEngine;
@synthesize imStorage=_imStorage;

- (void)startServiceWithOwner:(User *)owner
{
    [self.imEngine syncConfig];
    self.bIsServiceActive = YES;
    self.storage = [[BJIMStorage alloc]init];
}

- (void)stopService
{
    [self.operationQueue cancelAllOperations];
    self.bIsServiceActive = NO;
}

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message
{
    message.status = eMessageStatus_Sending;
    SendMsgOperation *operation = [[SendMsgOperation alloc] init];
    operation.imService = self;
    [self.operationQueue addOperation:operation];
}

- (void)retryMessage:(IMMessage *)message
{
    
}

#pragma mark - Post Message Delegate
- (void)onPostMessageSucc:(IMMessage *)message result:(SendMsgModel *)model
{
    message.status = eMessageStatus_Send_Succ;
}

- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error
{
    message.status = eMessageStatus_Send_Fail;
}
#pragma mark syncContact 


 - (void)synContact:(NSDictionary *)dictionary
{
//    User *currentUser = [[IMEnvironment shareInstance] owner];
//    if ([dictionary  isKindOfClass:[NSDictionary class]]) {
//        NSArray *groupList = [dictionary  objectForKey:@"group_list"];
//        NSArray *organizationList = [dictionary  objectForKey:@"organization_list"];
//        NSArray *studentList = [dictionary  objectForKey:@"student_list"];
//        for (NSDictionary *dict  in groupList) {
//            Contacts *contacts = [MTLJSONAdapter modelOfClass:[Contacts class] fromJSONDictionary:dictionary error:nil];
//            [self.storage insertOrUpdateContactOwner:currentUser contact:contacts];
//        }
//        
//        
//    }
//    
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


- (BJIMEngine *)imEngine
{
    if (_imEngine == nil)
    {
        _imEngine = [[BJIMEngine alloc] init];
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

- (BOOL)bIsServiceActive
{
    return _bIsServiceActive;
}

#pragma mark - application call back
- (void)applicationEnterForeground
{
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
