//
//  BJIMService+GroupManager.m
//  Pods
//
//  Created by Randy on 15/8/6.
//
//

#import "BJIMService+GroupManager.h"
#import "NSError+BJIM.h"
#import <BJHL-Common-iOS-SDK/BJCommonDefines.h>
#import "NetWorkTool.h"
#import "BJIMConstants.h"
#import "GroupMemberListData.h"
#import "GroupMember.h"
#import "HandleGetGroupMemberOperation.h"

static int ddLogLevel = DDLogLevelVerbose;

static char BJGroupMamagerDelegateKey;

@interface BJIMService ()
@property (nonatomic, strong) NSHashTable *groupManagerDelegates;
@end

@implementation BJIMService (GroupManager)

- (void)addGroupManagerDelegate:(id<IMGroupManagerResultDelegate>)delegate;
{
    [self.groupManagerDelegates addObject:delegate];
}

- (void)getGroupProfile:(int64_t)groupId;
{
    //1.检测登录 ok
    //2.检查group是否在本地存在 ok
    //3.更新群关系到本地 ok
    //4.更新group信息到内存、本地 并通知notifyGroupProfileChanged有更新
    //3.回调

    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyGetGroupProfile:groupId group:nil error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    User *owner = [IMEnvironment shareInstance].owner;
    [self.imEngine postGetGroupProfile:groupId callback:^(Group *result) {
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyGetGroupProfile:groupId group:nil error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        if (! result)
        {
            [weakSelf notifyGetGroupProfile:groupId group:nil error:[NSError bjim_errorWithReason:@"请求失败"]];
            return;
        }
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
        [group mergeValuesForKeysFromModel:result];
        [weakSelf.imStorage insertOrUpdateGroup:group];
        [weakSelf notifyGroupProfileChanged:group];
        [weakSelf notifyGetGroupProfile:groupId group:group error:nil];
    }];
}

- (void)leaveGroupWithGroupId:(int64_t)groupId;
{
    //0.检查登录状态
    //0.检查是否能离开 状态同步不实时，暂不检查 群是否存在
    //1.通知服务器
    //2.服务器成功后本地会话删除 通知上层会话更新。 deleteConversation
    //3.删除group和我的关系 删除内存中我的联系人 通知上层联系人列表更新。
    //4.通知退出成功
    
    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyLeaveGroup:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postLeaveGroup:groupId callback:^(NSError *err) {
        //请求成功
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyLeaveGroup:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        if (!err) {
            Conversation *conv = [weakSelf getConversationUserOrGroupId:groupId userRole:eUserRole_Anonymous owner:[IMEnvironment shareInstance].owner chat_t:eChatType_GroupChat];
            if ([weakSelf deleteConversation:conv owner:[IMEnvironment shareInstance].owner]) {
                [weakSelf notifyConversationChanged];
            }
            else
                DDLogError(@"Group Manager fail 删除会话失败");
            
            if (![weakSelf.imStorage deleteGroup:groupId user:[IMEnvironment shareInstance].owner]) {
                DDLogError(@"Group Manager fail 删除群和我的关系失败");
            }
            [weakSelf notifyContactChanged];
        }
        
        [weakSelf notifyLeaveGroup:groupId error:err];
    }];
}

- (void)disbandGroupWithGroupId:(int64_t)groupId;
{
    //0.检查登录状态
    //0.检查是否能解散 群是否存在
    //1.通知服务器
    //2.服务器成功后本地会话删除 通知上层会话更新。 deleteConversation
    //3.服务器成功后删除group所有成员关系、删除消息，并且删除group 通知上层联系人列表更新。 调用
    //5.通知解散成功

    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyDisbandGroup:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postDisBandGroup:groupId callback:^(NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [weakSelf notifyDisbandGroup:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        //请求成功
        if (!err) {
            Conversation *conv = [weakSelf getConversationUserOrGroupId:groupId userRole:eUserRole_Anonymous owner:[IMEnvironment shareInstance].owner chat_t:eChatType_GroupChat];
            if ([weakSelf deleteConversation:conv owner:[IMEnvironment shareInstance].owner]) {
                [weakSelf notifyConversationChanged];
            }
            
            if ([weakSelf.imStorage deleteGroup:groupId] == NO) {
                DDLogError(@"Group Manager fail 删除群所有关系失败");
            }
            [weakSelf notifyContactChanged];
        }
        
        [weakSelf notifyDisbandGroup:groupId error:err];
    }];
}

- (void)getGroupMemberWithGroupId:(int64_t)groupId page:(NSUInteger)page;
{
    //1.检测登录
    //2.检查group是否在本地存在 检查page的正确
    //3.更细群关系到本地
    //4.更新用户列表信息到本地 保证内存中只有一份user
    //3.回调
    
    if (page<1) {
        [self notifyGetGroupMembers:nil page:page groupId:groupId error:[NSError bjim_errorWithReason:@"page不能小于1" code:eError_paramsError]];
        return;
    }
    
    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyGetGroupMembers:nil page:page groupId:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postGetGroupMembers:groupId page:page callback:^(GroupMemberListData *members, NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [self notifyGetGroupMembers:nil page:page groupId:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        if (err) {
            [weakSelf notifyGetGroupMembers:nil page:page groupId:groupId error:err];
        }
        else
        {
            HandleGetGroupMemberOperation *operation = [[HandleGetGroupMemberOperation alloc] initWithService:self listData:members];
            [self.operationQueue addOperation:operation];
        }

    }];
}

- (void)changeGroupName:(NSString *)name groupId:(int64_t)groupId;
{
    //1.检测登录
    //2.检查group是否在本地存在
    //3.更新name到本地、内存
    //4.更新group信息到本地 并通知notifyGroupProfileChanged有更新
    //3.回调

    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyChangeGroupName:name groupId:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    [self.imEngine postChangeGroupName:groupId newName:name callback:^(NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [self notifyChangeGroupName:name groupId:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        group.groupName = name;
        [weakSelf.imStorage insertOrUpdateGroup:group];
        [weakSelf notifyGroupProfileChanged:group];
        [weakSelf notifyChangeGroupName:name groupId:groupId error:err];
    }];
}

- (void)setGroupMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId;
{
    //1.检测登录
    //2.检查group是否在本地存在
    //3.成功更新Group内存、更新groupMember到本地
    //3.回调

    Group *group = [self getGroup:groupId];
    if (group == nil) {
        [self notifyChangeMsgStatus:status groupId:groupId error:[NSError bjim_errorWithReason:@"群组不存在"]];
        return;
    }
    __WeakSelf__ weakSelf = self;
    User *owner = [IMEnvironment shareInstance].owner;
    [self.imEngine postSetGroupMsg:groupId msgStatus:status callback:^(NSError *err) {
        if (!weakSelf.bIsServiceActive)
        {
            [self notifyChangeMsgStatus:status groupId:groupId error:[NSError bjim_errorWithReason:@"已断开连接"]];
            return ;
        }
        GroupMember *groupMember = [weakSelf.imStorage queryGroupMemberWithGroupId:groupId userId:owner.userId userRole:owner.userRole];
        groupMember.msgStatus = status;
        group.msgStatus = status;
        [weakSelf.imStorage updateGroupMember:groupMember];
        [weakSelf notifyChangeMsgStatus:status groupId:groupId error:err];
    }];
}

#pragma mark - notify
- (void)notifyGetGroupProfile:(int64_t)groupId group:(Group *)group error:(NSError *)error;
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onGetGroupProfileResult:groupId:group:)]) {
            [delegate onGetGroupProfileResult:error groupId:groupId group:group];
        }
        
    }
}

- (void)notifyLeaveGroup:(int64_t)groupId error:(NSError *)error;
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onLeaveGroupResult:groupId:)]) {
            [delegate onLeaveGroupResult:error groupId:groupId];
        }

    }
}

- (void)notifyDisbandGroup:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onDisbandGroupResult:groupId:)]) {
            [delegate onDisbandGroupResult:error groupId:groupId];
        }

    }
}

- (void)notifyChangeGroupName:(NSString *)name groupId:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onChangeGroupNameResult:newName:groupId:)]) {
            [delegate onChangeGroupNameResult:error newName:name groupId:groupId];
        }
    }
}

- (void)notifyGetGroupMembers:(GroupMemberListData *)members page:(NSInteger)page groupId:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onGetGroupMemberResult:members:page:groupId:)]) {
            [delegate onGetGroupMemberResult:error members:members page:page groupId:groupId];
        }
    }
}

- (void)notifyChangeMsgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId error:(NSError *)error
{
    NSEnumerator *enumerator = [self.groupManagerDelegates objectEnumerator];
    id<IMGroupManagerResultDelegate> delegate = nil;
    while (delegate = [enumerator nextObject])
    {
        if ([delegate respondsToSelector:@selector(onChangeMsgStatusResult:msgStatus:groupId:)]) {
            [delegate onChangeMsgStatusResult:error msgStatus:status groupId:groupId];
        }
    }
}


#pragma mark - set get
- (void)setGroupManagerDelegates:(NSHashTable *)groupManagerDelegates
{
    objc_setAssociatedObject(self, &BJGroupMamagerDelegateKey, groupManagerDelegates, OBJC_ASSOCIATION_RETAIN);
}

- (NSHashTable *)groupManagerDelegates
{
    if (objc_getAssociatedObject(self, &BJGroupMamagerDelegateKey) == nil) {
        [self setGroupManagerDelegates:[NSHashTable weakObjectsHashTable]];
    }
    return objc_getAssociatedObject(self, &BJGroupMamagerDelegateKey);
}

@end