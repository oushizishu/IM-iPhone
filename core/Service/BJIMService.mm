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
@property (nonatomic, strong) NSHashTable *groupNoticeDelegates;
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
//    if (! [[NSUserDefaults standardUserDefaults] valueForKey:@"ResetMsgIdOperation"])
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
    
    [self notifyDeliverMessage:message errorCode:error.code error:[error.userInfo valueForKey:@"NSLocalizedFailureReason"]];
    
    if(error.code == 510007)//被对方拉黑
    {
        PassiveBlacklistOperation *passiveOperation = [[PassiveBlacklistOperation alloc] init];
        passiveOperation.message = message;
        passiveOperation.imService = self;
        
        [self.writeOperationQueue addOperation:passiveOperation];
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
    
    if (userId == USER_STRANGER && userRole == eUserRole_Stanger) {
        return [self getStranger];
    }
    
    if (userId == USER_FRESH_FANS && userRole == eUserRole_Fans) {
        return [self getFreshFans];
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

- (BJNetRequestOperation*)uploadGroupFile:(NSString*)attachment
                       filePath:(NSString*)filePath
                       fileName:(NSString*)fileName
                       callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
                       progress:(onProgress)progress
{
    return [self.imEngine uploadGroupFile:attachment filePath:filePath fileName:fileName callback:callback progress:progress];
}

- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback
{
    [self.imEngine addGroupFile:groupId storage_id:storage_id fileName:fileName callback:callback];
}

- (BJNetRequestOperation*)downloadGroupFile:(NSString*)fileUrl
                         filePath:(NSString*)filePath
                         callback:(void(^)(NSError *error))callback
                         progress:(onProgress)progress
{
    return [self.imEngine downloadGroupFile:fileUrl filePath:filePath callback:callback progress:progress];
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
    [self.imEngine setGroupMsgStatus:status groupId:groupId callback:callback];
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
                callback:(void(^)(NSError *error))callback
{
    [self.imEngine removeGroupNotice:notice_id callback:callback];
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
            User *owner = owner = [IMEnvironment shareInstance].owner;
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

- (SocialContacts *)getSocialUser:(User *)user owner:(User *)owner
{
    return [self.imStorage.socialContactsDao loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
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

- (User *)getStranger
{
    if (_stanger == nil) {
        _stanger = [self.imStorage.userDao loadUser:USER_STRANGER role:eUserRole_Stanger];
        if (_stanger == nil) {
            _stanger = [[User alloc] init];
            _stanger.userId = USER_STRANGER;
            _stanger.userRole = eUserRole_Stanger;
            _stanger.name = @"陌生人消息";
            [self.imStorage.userDao insertOrUpdateUser:_stanger];
        }
    }
    return _stanger;
}

- (Conversation *)getStrangerConversation
{
    User *owner = [IMEnvironment shareInstance].owner;
    User *stanger = [self getStranger];
    return [self.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:stanger.userId userRole:stanger.userRole chatType:eChatType_Chat];
}

- (NSArray *)getMyStrangerConversations
{
    User *owner = [IMEnvironment shareInstance].owner;
    
    NSMutableArray *reArray;
    reArray = [[NSMutableArray alloc] init];
    NSArray *list = [self.imStorage.conversationDao loadAllStrangerWithOwnerId:owner.userId userRole:owner.userRole];
    
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

- (void)clearStangerConversationUnreadCount
{
    User *user = [IMEnvironment shareInstance].owner;
    [self.imStorage.nFansContactDao deleteAllFreshFans:user];
    Conversation *stangerConversation = [self.imStorage.conversationDao loadWithOwnerId:user.userId ownerRole:user.userRole otherUserOrGroupId:USER_STRANGER userRole:eUserRole_Stanger chatType:eChatType_Chat];
    if (stangerConversation) {
        stangerConversation.unReadNum = 0;
        [self.imStorage.conversationDao update:stangerConversation];
        [self notifyConversationChanged];
        
        NSInteger allUnReadnum = [self.imStorage sumOfAllConversationUnReadNumOwnerId:user.userId userRole:user.userRole];
        NSInteger otherUnReadNum = [self.imStorage.conversationDao sumOfAllUnReadNumBeenHiden:user];
        [self notifyUnReadNumChanged:allUnReadnum other:otherUnReadNum];
    }
}

- (NSInteger)getMyStrangerConversationsCountHaveNoRead
{
    User *owner = [IMEnvironment shareInstance].owner;
    return [self.imStorage.conversationDao countOfStrangerCovnersationAndUnreadNumNotZero:owner.userId userRole:owner.userRole];
}

- (User *)getFreshFans
{
    if (_nFans == nil) {
        _nFans = [self.imStorage.userDao loadUser:USER_FRESH_FANS role:eUserRole_Fans];
        if (_nFans == nil) {
            _nFans = [[User alloc] init];
            _nFans.userId = USER_FRESH_FANS;
            _nFans.userRole = eUserRole_Fans;
            _nFans.name = @"新粉丝";
            [self.imStorage.userDao insertOrUpdateUser:_nFans];
        }
    }
    return _nFans;
}

- (Conversation *)getFreshFansConversation
{
    User *owner = [IMEnvironment shareInstance].owner;
    User *newFans = [self getFreshFans];
    return [self.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:newFans.userId userRole:newFans.userRole chatType:eChatType_Chat];
}

- (NSArray*)getMyFreshFans
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadALLFreshFans:user];
}

- (void)clearMyFreshFans
{
    User *user = [IMEnvironment shareInstance].owner;
    [self.imStorage.nFansContactDao deleteAllFreshFans:user];
    Conversation *freshConversation = [self.imStorage.conversationDao loadWithOwnerId:user.userId ownerRole:user.userRole otherUserOrGroupId:USER_FRESH_FANS userRole:eUserRole_Fans chatType:eChatType_Chat];
    if (freshConversation) {
        freshConversation.unReadNum = 0;
        [self.imStorage.conversationDao update:freshConversation];
        [self notifyConversationChanged];
    }
}

- (NSInteger)getMyFreshFansCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getALLFreshFansCount:user];
}

- (NSArray *)getMyMutualUsers
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllMutualUser:user];
}

- (NSInteger)getMyMutualUsersCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllMutualUserCount:user];
}

- (NSArray *)getMyFans
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllFans:user];
}

- (NSInteger)getMyFansCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllFansCount:user];
}

- (NSArray *)getMyFansBelongToTeacher
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllFansTeacher:user];
}

- (NSInteger)getMyFansBelongToTeacherCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllFansTeacherCount:user];
}

- (NSArray *)getMyFansBelongToStudent
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllFansStudent:user];
}

- (NSInteger)getMyFansBelongToStudentCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllFansStudentCount:user];
}

- (NSArray *)getMyFansBelongToInstitution
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllFansInstitution:user];
}

- (NSInteger)getMyFansBelongToInstitutionCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllFansInstitutionCount:user];
}

- (NSArray *)getMyAttentions
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllAttentions:user];
}

- (NSInteger)getMyAttentionsCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllAttentionsCount:user];
}

- (NSArray *)getMyAttentionsBelongToTeacher
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllAttentionsTeacher:user];
}

- (NSInteger)getMyAttentionsBelongToTeacherCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllAttentionsTeacherCount:user];
}

- (NSArray *)getMyAttentionsBelongToStudent
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllAttentionsStudent:user];
}

- (NSInteger)getMyAttentionsBelongToStudentCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllAttentionsStudentCount:user];
}

- (NSArray *)getMyAttentionsBelongToInstitution
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllAttentionsInstitution:user];
}

- (NSInteger)getMyAttentionsBelongToInstitutionCount
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao getAllAttentionsInstitutionCount:user];
}

- (NSArray *)getMyBlackList
{
    User *user = [IMEnvironment shareInstance].owner;
    return [self.imStorage.socialContactsDao loadAllBlacks:user];
}

- (BOOL)getIsStanger:(User*)fromUser withUser:(User*)toUser
{
    //初始时，设定默认不是陌生人关系。
    BOOL isStranger = NO;
    User *owner = [IMEnvironment shareInstance].owner;
    
    if (owner.userId == fromUser.userId && owner.userRole == fromUser.userRole) {
        // 判断我和对方是不是陌生人关系
        if (fromUser.userRole != eUserRole_Student && toUser.userRole == eUserRole_Student) {
            // 学生给非学生发消息，都不是陌生人
            isStranger = NO;
        } else if (toUser.userRole != eUserRole_Student
                   && toUser.userRole != eUserRole_Teacher
                   && toUser.userRole != eUserRole_Institution) {
            // 对方非主要角色，都不是陌生人
            isStranger = NO;
        } else {
            //我是任一角色，对方不是学生，查表判断
            SocialContacts *social = [self.imStorage.socialContactsDao loadContactId:toUser.userId contactRole:toUser.userRole ownerId:fromUser.userId ownerRole:fromUser.userRole];
            
            if (!social) {
                isStranger = YES;
            } else {
                if ((social.focusType == eIMFocusType_None || social.focusType == eIMFocusType_Passive)
                    && (social.tinyFoucs == eIMTinyFocus_None)) {
                    isStranger = YES;
                }
            }
        }
    } else if (owner.userId == toUser.userId && owner.userRole == toUser.userRole) {
        // 判断对方和我是不是陌生人关系
        if (fromUser.userRole == eUserRole_Student && toUser.userRole != eUserRole_Student) {
            // 学生发来的消息， 并且我不是学生。不是陌生人
            isStranger = NO;
        } else if (fromUser.userRole != eUserRole_Student
                   && fromUser.userRole != eUserRole_Teacher
                   && fromUser.userRole != eUserRole_Institution) {
            // 发送者非主要角色，不是陌生人
            isStranger = NO;
        } else {
           // 对方不是学生，我是任一角色，查表判断
            SocialContacts *social = [self.imStorage.socialContactsDao loadContactId:fromUser.userId contactRole:fromUser.userRole ownerId:toUser.userId ownerRole:toUser.userRole];
            
            if (!social) {
                isStranger = YES;
            } else {
               if ((social.focusType == eIMFocusType_None || social.focusType == eIMFocusType_Active)) {
                   isStranger = YES;
               }
            }
        }
    }
    
    return isStranger;
}

- (void)addAttention:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result, User *user))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postAddAttention:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        if(result.code == 0)
        {
            User *owner = [IMEnvironment shareInstance].owner;
            SetSocialFocusOperation *operation = [[SetSocialFocusOperation alloc] init];
            operation.imService = weakSelf;
            operation.owner = owner;
            operation.contact = contact;
            operation.bAddFocus = YES;
            
            contact.focusType = (IMFocusType)[[result.data objectForKey:@"focus_type"] integerValue];
            
            contact.focusTime = [NSDate dateWithTimeIntervalSince1970:[[result.data objectForKey:@"time"] integerValue]];
            
            [weakSelf.writeOperationQueue addOperation:operation];
        }
        if (callback)
            callback(err,result, contact);
    }];
}

- (void)cancelAttention:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result, User *user))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postCancelAttention:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        if(result.code == 0)
        {
            User *owner = [IMEnvironment shareInstance].owner;
            SetSocialFocusOperation *operation = [[SetSocialFocusOperation alloc] init];
            operation.imService = weakSelf;
            operation.owner = owner;
            operation.contact = contact;
            operation.bAddFocus = NO;
            
            contact.focusType = (IMFocusType)[[result.data objectForKey:@"focus_type"] integerValue];
            
            contact.focusTime = [NSDate dateWithTimeIntervalSince1970:[[result.data objectForKey:@"time"] integerValue]];
            
            contact.tinyFocus = eIMTinyFocus_None;
            
            [weakSelf.writeOperationQueue addOperation:operation];
        }
        if (callback)
            callback(err,result, contact);
    }];
}

- (void)addBlacklist:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postAddBlacklist:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        if (result.code == 0) {
            User *owner = [IMEnvironment shareInstance].owner;
            if (result.code == 0) {
                [weakSelf.imStorage.socialContactsDao setContactBacklist:eIMBlackStatus_Active contact:contact owner:owner];
                if (owner.userRole == eUserRole_Teacher) {
                    
                }else if(owner.userRole == eUserRole_Student)
                {
                    [weakSelf.imStorage.studentDao deleteContactId:contact.userId contactRole:contact.userRole owner:owner];
                }else if(owner.userRole == eUserRole_Institution)
                {
                    
                }
                [weakSelf notifyContactChanged];
            }
        }
        if (callback)
            callback(err,result);
    }];
}

- (void)cancelBlacklist:(User*)contact callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine postCancelBlacklist:contact.userId role:contact.userRole callback:^(NSError *err ,BaseResponse *result) {
        if(result.code == 0)
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

- (void)appendOperationAfterContacts:(id)operation
{
    [self.syncContactsOperationQueue addOperation:operation];
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

@end
