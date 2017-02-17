//
//  BJIMService.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "BJIMService.h"
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
#import "HistoryDirtyDataCleanOperation.h"

#import "BJIMAbstractEngine.h"
#import "BJIMHttpEngine.h"
#import "BJIMSocketEngine.h"

#import "NetWorkTool.h"
#import "BaseResponse.h"

#import "NSUserDefaults+IMSDK.h"

#import <BJHL-Foundation-iOS/BJHL-Foundation-iOS.h>
#import "TransformContactInfoToNewDBOperation.h"

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
@property (nonatomic, strong) NSHashTable *groupNoticeDelegates;
@property (nonatomic, strong) NSHashTable *loadMoreMessagesDelegates;
@property (nonatomic, strong) NSHashTable *recentContactsDelegates;
@property (nonatomic, strong) NSHashTable *userInfoDelegates;
@property (nonatomic, strong) NSHashTable *groupInfoDelegates;
@property (nonatomic, strong) NSHashTable *disconnectionStateDelegates;
@property (nonatomic, strong) NSHashTable *imLoginLogoutDelegates;
@property (nonatomic, strong) NSHashTable *imUnReadNumChangedDelegates;
@property (nonatomic, strong) NSHashTable *imUserAvatarInvalidDelegates;

@property (nonatomic, strong) User *systemSecretary;
@property (nonatomic, strong) User *customeWaiter;

@property (nonatomic, strong, readonly) NSOperationQueue *readOperationQueue; //DB 读操作线程
@property (nonatomic, strong, readonly) NSOperationQueue *sendMessageOperationQueue; // 消息发送在独立线程上操作
@property (nonatomic, strong, readonly) NSOperationQueue *receiveMessageOperationQueue; // 接受消息在独立线程上操作
@property (nonatomic, strong, readonly) NSOperationQueue *syncContactsOperationQueue; // 联系人数据量比较大， 放在单独线程中

/* 标记当前是否从后台进入到前台 */
@property (nonatomic, assign) BOOL bIsEnterFromBackground;

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
    
    [self.imEngine syncConfig];
    
    // 提交用户信息
    [NetWorkTool hermesSetUserName:owner.name userAvatar:owner.avatar];
    
    
    // bugfix
    /** 初始化启动 msgId 修改线程。老版本中包含部分 msgId 没有做对齐处理。在线程中修复数据.
     修复过一次以后就不再需要了*/
//    if (! [[NSUserDefaults standardUserDefaults] valueForKey:@"ResetMsgIdOperation"])
    // 4.1 之前的版本需要将联系人数据迁移到新的库中
    NSComparisonResult result = [BJIM_VERSION_43 compare:[NSUserDefaults getSavedIMSDKVersion]];
    if (result == NSOrderedDescending) {
       // 需要做联系人迁移Deprecated ===> 做历史关注数据清除
//        TransformContactInfoToNewDBOperation *operation = [[TransformContactInfoToNewDBOperation alloc] init];
//        operation.imService = self;
//        [self.syncContactsOperationQueue addOperation:operation];
        HistoryDirtyDataCleanOperation *operation = [[HistoryDirtyDataCleanOperation alloc] init];
        operation.imService = self;
        // 主要更新 message 表。 在读之前将数据更新过来
        [self.readOperationQueue addOperation:operation];
    }
    
    [self.imEngine syncContacts];
    
    {
        ResetMsgIdOperation *operation = [[ResetMsgIdOperation alloc] init];
        operation.imService = self;
        [self.writeOperationQueue addOperation:operation];
    }
    
    [NSUserDefaults saveIMSDKVersion:[[IMEnvironment shareInstance] getCurrentVersion]];
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
    [self.sendMessageOperationQueue cancelAllOperations];
    [self.receiveMessageOperationQueue cancelAllOperations];
    [self.syncContactsOperationQueue cancelAllOperations];
    
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
    [message.msgStatictis markStartSend];
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
    [message.msgStatictis markStartSend];
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

- (void)resetAllUnReadNum:(User *)owner
{
    [self.imStorage.conversationDao resetAllUnReadNum:owner];
    [self notifyUnReadNumChanged:0 other:0];
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
    
    [self notifyDeliverMessage:message errorCode:error.code error:[error.userInfo valueForKey:@"NSLocalizedFailureReason"]];
    
    if(error.code == 510007)//被对方拉黑
    {
    }else if(error.code == 510008)//自己拉黑对方
    {
        
    }
}

#pragma mark - Polling Delegate
- (void)onShouldStartPolling
{
    if (! self.bIsServiceActive) return;
    PrePollingOperation *operation = [[PrePollingOperation alloc] init];
    operation.imService = self;
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
               isFirstGetMsg:(BOOL)isFirstGetMsg
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.model = model;
    operation.minMsgId = minMsgId;
    operation.userId = userId;
    operation.userRole = userRole;
    operation.groupId = groupId;
    operation.isFirstGetMsg = isFirstGetMsg;
    
    [self.receiveMessageOperationQueue addOperation:operation];
}

- (void)onGetMsgFailMinMsgId:(NSString *)minMsgId
                      userId:(int64_t)userId
                    userRole:(IMUserRole)userRole
                     groupId:(int64_t)groupId
               isFirstGetMsg:(BOOL)isFirstGetMsg
{
    if (!self.bIsServiceActive)return;
    HandleGetMsgOperation *operation = [[HandleGetMsgOperation alloc] init];
    operation.imService = self;
    operation.minMsgId = minMsgId;
    operation.groupId = groupId;
    operation.userId = userId;
    operation.userRole = userRole;
    operation.isFirstGetMsg = isFirstGetMsg;
    
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
    NSMutableArray *reArray;
    reArray = [[NSMutableArray alloc] init];
    NSArray *list = [self.imStorage.conversationDao loadAllWithOwnerId:owner.userId userRole:owner.userRole];
    
    if (list != nil) {
        [reArray addObjectsFromArray:list];
    }
    
    
    __WeakSelf__ weakSelf = self;
    [reArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Conversation *conversation = (Conversation *)obj;
        conversation.imService = weakSelf;
    }];
    return reArray;
}

- (Conversation *)getConversationUserOrGroupId:(int64_t)userOrGroupId
                                      userRole:(IMUserRole)userRole
                                         ownerId:(int64_t)ownerId
                                     ownerRole:(IMUserRole)ownerRole
                                        chat_t:(IMChatType)chat_t
{
    Conversation *converstaion = [self.imStorage.conversationDao loadWithOwnerId:ownerId ownerRole:ownerRole otherUserOrGroupId:userOrGroupId userRole:userRole chatType:chat_t];
    
    if (! converstaion.imService) {
        converstaion.imService = self;
    }
    
    return converstaion;
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

- (void)refreshMyContacts
{
    [self.imEngine syncContacts];
}

- (void)getUserOnlineStatus:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(IMUserOnlineStatus onlineStatus))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postGetUserOnLineStatus:userId role:userRole callback:^(IMUserOnlieStatusResult *result) {
        User *user = [weakSelf getUser:userId role:userRole];
        if (result) {
            user.onlineStatus = result.onlineStatus;
            [weakSelf.imStorage.userDao insertOrUpdateUser:user];
        }
        callback(user.onlineStatus);
    }];
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
            
            GroupMember *_groupMember = [weakSelf.imStorage.groupMemberDao loadMember:owner.userId userRole:owner.userRole groupId:group.groupId];
            
            if(_groupMember != nil)
            {
                _groupMember.msgStatus = group.msgStatus;
                _groupMember.canDisband = group.canDisband;
                _groupMember.canLeave = group.canLeave;
                _groupMember.remarkHeader = group.remarkHeader;
                _groupMember.remarkName = group.remarkName;
                _groupMember.pushStatus = group.pushStatus;
                
                [weakSelf.imStorage.groupMemberDao insertOrUpdate:_groupMember];
            }
            [group mergeValuesForKeysFromModel:result];
            [weakSelf.imStorage.groupDao insertOrUpdate:group];
            [weakSelf notifyGroupProfileChanged:group];
        }];
    }
    return group;
}

- (void)getGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback
{
    [self.imEngine getGroupDetail:groupId callback:callback];
}

- (void)getGroupMembers:(int64_t)groupId page:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void(^)(NSError *error ,NSArray *members,BOOL hasMore,BOOL is_admin,BOOL is_major))callback
{
    [self.imEngine getGroupMembers:groupId page:page pageSize:pageSize callback:callback];
}

- (void)isAdmin:(int64_t)groupId callback:(void(^)(NSError *error, IMGroupMemberRole groupMemberRole))callback {
    return [self.imEngine isAdmin:groupId callback:callback];
}

- (void)getSearchMemberList:(int64_t)groupId query:(NSString *)query callback:(void(^)(NSError *error, NSArray<GroupDetailMember *> *memberList))callback {
    return [self.imEngine getSearchMemberList:groupId query:query callback:callback];
}

- (void)setGroupMemberForbid:(int64_t)groupId
                 user_number:(int64_t)user_number
                   user_role:(int64_t)user_role
                      status:(int64_t)status
                    callback:(void(^)(NSError *error))callback {
    [self.imEngine setGroupMemberForbid:groupId user_number:user_number user_role:user_role status:status callback:callback];
}

- (BOOL)hasContactOwner:(User *)owner
                contact:(User *)contact {
    return [self.imStorage.contactsDao hasContactOwner:owner contact:contact];
}

- (void)getGroupMemberProfile:(int64_t)groupId
                  user_number:(int64_t)user_number
                     userRole:(IMUserRole)userRole
                     callback:(void (^)(NSError *error, MemberProfile *memberProfile))callback {
    return [self.imEngine getGroupMemberProfile:groupId user_number:user_number userRole:userRole callback:callback];
}

- (void)transferGroup:(int64_t)groupId
          transfer_id:(int64_t)transfer_id
        transfer_role:(int64_t)transfer_role
             callback:(void(^)(NSError *error))callback
{
    [self.imEngine transferGroup:groupId transfer_id:transfer_id transfer_role:transfer_role callback:callback];
}

- (void)setGroupAvatar:(int64_t)groupId
                avatar:(int64_t)avatar
              callback:(void(^)(NSError *error))callback
{
    [self.imEngine setGroupAvatar:groupId avatar:avatar callback:callback];
}

- (void)setGroupNameAvatar:(int64_t)groupId
                 groupName:(NSString*)groupName
                    avatar:(int64_t)avatar
                  callback:(void(^)(NSError *error))callback
{
    [self.imEngine setGroupNameAvatar:groupId groupName:groupName avatar:avatar callback:callback];
}

- (void)setGroupAdmin:(int64_t)groupId
          user_number:(int64_t)user_number
            user_role:(int64_t)user_role
               status:(int64_t)status
             callback:(void(^)(NSError *error))callback
{
    [self.imEngine setGroupAdmin:groupId user_number:user_number user_role:user_role status:status callback:callback];
}

- (void)removeGroupMember:(int64_t)groupId
              user_number:(int64_t)user_number
                user_role:(int64_t)user_role
                 callback:(void(^)(NSError *error))callback
{
    [self.imEngine removeGroupMember:groupId user_number:user_number user_role:user_role callback:callback];
}

- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback
{
    [self.imEngine postLeaveGroup:groupId callback:callback];
}

- (void)postDisBandGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback
{
    [self.imEngine postDisBandGroup:groupId callback:callback];
}

- (void)getGroupFiles:(int64_t)groupId
         last_file_id:(int64_t)last_file_id
             callback:(void(^)(NSError *error ,NSArray<GroupFile *> *list))callback
{
    [self.imEngine getGroupFiles:groupId last_file_id:last_file_id callback:callback];
}

- (BJCNNetRequestOperation*)uploadGroupFile:(NSString*)attachment
                                 filePath:(NSString*)filePath
                                 fileName:(NSString*)fileName
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
                                 progress:(BJCNOnProgress)progress
{
    [self.imEngine uploadGroupFile:attachment filePath:filePath fileName:fileName callback:callback progress:progress];
    return nil;
}

- (BJCNNetRequestOperation*)uploadImageFile:(NSString*)fileName
                                 filePath:(NSString*)filePath
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
{
    [self.imEngine uploadImageFile:fileName filePath:filePath callback:callback];
    return nil;
}

- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback
{
    [self.imEngine addGroupFile:groupId storage_id:storage_id fileName:fileName callback:callback];
}

- (BJCNNetRequestOperation*)downloadGroupFile:(NSString*)fileUrl
                         filePath:(NSString*)filePath
                         callback:(void(^)(NSError *error))callback
                         progress:(BJCNOnProgress)progress
{
    [self.imEngine downloadGroupFile:fileUrl filePath:filePath callback:callback progress:progress];
    return nil;
}

- (void)previewGroupFile:(int64_t)groupId
                 file_id:(int64_t)file_id
                callback:(void(^)(NSError *error ,NSString *url))callback
{
    [self.imEngine previewGroupFile:groupId file_id:file_id callback:callback];
}

- (void)setGroupMsgStatus:(int64_t)status
                  groupId:(int64_t)groupId
                 callback:(void(^)(NSError *error))callback
{
    WS(weakSelf);
    [self.imEngine setGroupMsgStatus:status groupId:groupId callback:^(NSError *error) {
        callback(error);
        if (error == nil) {
            User *owner = [IMEnvironment shareInstance].owner;
            Group *group = [weakSelf.imStorage.groupDao load:groupId];
            Conversation *conv = [weakSelf getConversationUserOrGroupId:groupId userRole:eUserRole_Anonymous ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_GroupChat];
            if (status == 3) {
                conv.relation = eConversation_Relation_Group_Closed;
                group.pushStatus = eGroupPushStatus_open;
            }else
            {
                conv.relation = eConverastion_Relation_Normal;
                group.pushStatus = eGroupPushStatus_close;
            }
            [weakSelf.imStorage.conversationDao update:conv];
            [weakSelf.imStorage.groupDao insertOrUpdate:group];
            [weakSelf notifyConversationChanged];
        }
    }];
    
}

- (void)deleteGroupFile:(int64_t)groupId
                file_id:(int64_t)file_id
               callback:(void(^)(NSError *error))callback
{
    [self.imEngine deleteGroupFile:groupId file_id:file_id callback:callback];
}

-(void)createGroupNotice:(int64_t)groupId
                 content:(NSString*)content
                callback:(void(^)(NSError *error))callback
{
    [self.imEngine createGroupNotice:groupId content:content callback:callback];
}

-(void)getGroupNotice:(int64_t)groupId
              last_id:(int64_t)last_id
            page_size:(int64_t)page_size
             callback:(void(^)(NSError *error ,BOOL isAdmin ,NSArray<GroupNotice*> *list ,BOOL hasMore))callback
{
    [self.imEngine getGroupNotice:groupId last_id:last_id page_size:page_size callback:callback];
}

-(void)removeGroupNotice:(int64_t)notice_id
                group_id:(int64_t)group_id
                callback:(void(^)(NSError *error))callback
{
    [self.imEngine removeGroupNotice:notice_id group_id:group_id callback:callback];
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
            
            User *owner = owner = [IMEnvironment shareInstance].owner;
            [weakSelf.imStorage.contactsDao insertOrUpdateContact:user owner:owner];
            Conversation *conversation = [weakSelf.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:user.userId userRole:user.userRole chatType:eChatType_Chat];
            if (conversation && conversation.status == 0) {
                [weakSelf notifyConversationChanged];
            }
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
    return [self.imStorage.contactsDao hasContactOwner:user contact:contact];
}

- (BOOL)hasInsitituion:(int64_t)institutionId ofUser:(User *)user
{
    User *contact = [[User alloc] init];
    contact.userId = institutionId;
    contact.userRole = eUserRole_Institution;
    return [self.imStorage.contactsDao hasContactOwner:user contact:contact];
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
    return [self.imStorage.contactsDao loadAll:user role:eUserRole_Teacher];
}

- (NSArray *)getStudentContactsWithUser:(User *)user
{
    return [self.imStorage.contactsDao loadAll:user role:eUserRole_Student];
}

- (NSArray *)getInstitutionContactsWithUser:(User *)user
{
    return [self.imStorage.contactsDao loadAll:user role:eUserRole_Institution];
}

- (void)addRecentContactId:(int64_t)userId
               contactRole:(IMUserRole)userRole
                  callback:(void (^)(BaseResponse *))callback
{
    [NetWorkTool hermesAddRecentContactId:userId role:userRole succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
       if (callback)
       {
           NSError *error;
           BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
           callback(result);
       }
    } failure:^(NSError *error, BJCNRequestParams *params) {
       if (callback)
           callback(nil);
    }];
}

#pragma mark - 关系操作，拉黑
- (void)addBlackContactId:(int64_t)userId
              contactRole:(IMUserRole)userRole
                    owner:(User *)owner
                 callback:(void(^)(BaseResponse *response))callback
{
    __weak typeof(self) weakSelf = self;
    [self.imEngine postAddBlacklist:userId role:userRole callback:^(NSError *error, BaseResponse *result) {
        if(error == nil && weakSelf) {
            User *user = [weakSelf.imStorage.userDao loadUser:userId role:userRole];
            if (! user) {
                user = [[User alloc] init];
                user.userId = userId;
                user.userRole = userRole;
            }
            [weakSelf.imStorage.contactsDao addBlack:user owner:owner];
        }
        if (callback) {
            callback(result);
        }
    }];
}

- (void)removeBlackContactId:(int64_t)userId
                 contactRole:(IMUserRole)userRole
                       owner:(User *)owner
                    callback:(void(^)(BaseResponse *reponse))callback
{
    __weak typeof(self) weakSelf = self;
    [self.imEngine postCancelBlacklist:userId role:userRole callback:^(NSError *error, BaseResponse *result) {
        if (error == nil && weakSelf) {
            User *user = [weakSelf.imStorage.userDao loadUser:userId role:userRole];
            if (! user) {
                user = [[User alloc] init];
                user.userId = userId;
                user.userRole = userRole;
            }
            [weakSelf.imStorage.contactsDao removeBlack:user owner:owner];
            if (callback) {
                callback(result);
            }
        }
    }];
}

- (void)getAllBlackOwner:(User *)owner
                callback:(void(^)(NSArray<User *> *blacklist))callback
{
    if (! callback) return;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *result = [weakSelf.imStorage.contactsDao loadAllBlack:owner];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(result);
        });
    });
}

#pragma mark -系统小秘书 & 客服
//系统小秘书
- (User *)getSystemSecretary
{
    if (_systemSecretary == nil)
    {
        _systemSecretary = [[User alloc] init];
        _systemSecretary.userId = USER_SYSTEM_SECRETARY;
        _systemSecretary.userRole = eUserRole_System;
        _systemSecretary.name = @"系统小秘书";
    }
    return _systemSecretary;
}
// 客服
- (User *)getCustomWaiter
{
    if (_customeWaiter == nil)
    {
        _customeWaiter = [[User alloc] init];
        _customeWaiter.userId = USER_CUSTOM_WAITER;
        _customeWaiter.userRole = eUserRole_Kefu;
        _customeWaiter.name = @"客服";
    }
    return _customeWaiter;
}

- (void)clearConversationAndMessage
{
    User *user = [IMEnvironment shareInstance].owner;
    
    NSArray *conversationList = [self.imStorage.conversationDao loadAllNoConditionWithOwnerId:user.userId userRole:user.userRole];
    
    for(int i = 0; i < [conversationList count]; i++)
    {
        Conversation *conversation = [conversationList objectAtIndex:i];
        [self.imStorage.messageDao deleteAllMessageInConversation:conversation.rowid];
    }
    [self.imStorage.conversationDao deleteAllConversation:user.userId userRole:user.userRole];
    
    [self notifyConversationChanged];
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

- (void)appendOperationAfterContacts:(id)operation
{
    [self.syncContactsOperationQueue addOperation:operation];
}

#pragma mark - autoresponse
- (void)addAutoResponseWithContent:(NSString *)content
                           success:(void(^)(NSInteger contentId))succss
                           failure:(void(^)(NSError *error))failure
{
    User *user = [IMEnvironment shareInstance].owner;
    [NetWorkTool hermesAddAutoResponseWithUserId:user.userId role:user.userRole content:content success:succss failure:failure];
}

- (void)editAutoResponseWithContent:(NSString *)content
                          contentId:(NSInteger)contentId
                            success:(void(^)(NSInteger contentId))succss
                            failure:(void(^)(NSError *error))failure
{
    User *user = [IMEnvironment shareInstance].owner;
    [NetWorkTool hermesEditAutoResponseWithUserId:user.userId role:user.userRole contentId:contentId content:content success:succss failure:failure];
}

- (void)setEnableAutoResponseWithEnable:(BOOL)enable
                                success:(void(^)())succss
                                failure:(void(^)(NSError *error))failure
{
    User *user = [IMEnvironment shareInstance].owner;
    [NetWorkTool hermesSetAutoResponseWithUserId:user.userId role:user.userRole enable:enable success:succss failure:failure];
}

- (void)setSelectedAutoResponseWithContentId:(NSInteger)contentId
                                     success:(void(^)())succss
                                     failure:(void(^)(NSError *error))failure
{
    User *user = [IMEnvironment shareInstance].owner;
    [NetWorkTool hermesSetAutoResponseWithUserId:user.userId role:user.userRole contentId:contentId success:succss failure:failure];
}

- (void)delAutoResponseWithContentId:(NSInteger)contentId
                             success:(void(^)())succss
                             failure:(void(^)(NSError *error))failure
{
    User *user = [IMEnvironment shareInstance].owner;
    [NetWorkTool hermesDelAutoResponseWithUserId:user.userId role:user.userRole contentId:contentId success:succss failure:failure];
}

- (void)getAllAutoResponseWithSuccess:(void(^)(AutoResponseList *result))succss
                              failure:(void(^)(NSError *error))failure
{
    User *user = [IMEnvironment shareInstance].owner;
    [NetWorkTool hermesGetAllAutoResponseWithUserId:user.userId role:user.userRole success:succss failure:failure];
}



#pragma mark - application call back
- (void)applicationEnterForeground
{
    if (self.bIsServiceActive && self.bIsEnterFromBackground) {
        [self.imEngine start];
        self.bIsEnterFromBackground = NO;
    }
}

- (void)applicationEnterBackground
{
    self.bIsEnterFromBackground = YES;
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

- (void)addNewGroupNoticeDelegate:(id<IMNewGRoupNoticeDelegate>)delegate
{
    if (self.groupNoticeDelegates == nil)
    {
        self.groupNoticeDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    [self.groupNoticeDelegates addObject:delegate];
}
- (void)notifyNewGroupNotice
{
    NSEnumerator *enumerator = [self.groupNoticeDelegates objectEnumerator];
    id<IMNewGRoupNoticeDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didNewGroupNotice)])
            [delegate didNewGroupNotice];
    }
}

- (void)addLoadMoreMessagesDelegate:(id<IMLoadMessageDelegate>)delegate
{
    if (self.loadMoreMessagesDelegates == nil)
    {
        self.loadMoreMessagesDelegates = [NSHashTable weakObjectsHashTable];
    }
    
    // 只有在正常聊天时才需要加载消息列表， 所以只保持一个监听。否则会导致消息错乱
    [self.loadMoreMessagesDelegates removeAllObjects];
    
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

- (void)notifyUnReadNumChanged:(NSInteger)unReadNum other:(NSInteger)otherNum
{
    NSEnumerator *enumerator = [self.imUnReadNumChangedDelegates objectEnumerator];
    id<IMUnReadNumChangedDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(didUnReadNumChanged:otherUnReadNum:)])
        {
            [delegate didUnReadNumChanged:unReadNum otherUnReadNum:otherNum];
        }
    }
}

- (void)addUserAvatarInvalidDelegate:(id<IMUserAvatarInvalidDelegate>)delegate
{
    if (self.imUserAvatarInvalidDelegates == nil) {
        self.imUserAvatarInvalidDelegates = [NSHashTable weakObjectsHashTable];
    }
    [self.imUserAvatarInvalidDelegates addObject:delegate];
}

- (void)notifyUserAvatarInvalid:(User *)user
{
    NSEnumerator *enumerator = [self.imUserAvatarInvalidDelegates objectEnumerator];
    id<IMUserAvatarInvalidDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onUserAvatarInvalid:)])
        {
            [delegate onUserAvatarInvalid:user];
        }
    }
}

@end
