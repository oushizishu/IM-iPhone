//
//  BJIMEngine.m
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "BJIMEngine.h"
#import "NetWorkTool.h"
#import "BaseResponse.h"
#import "BJIMStorage.h"
#import "BJTimer.h"
#import "RecentContactModel.h"
#import "NSError+BJIM.h"
#import "GetGroupMemberModel.h"
#import "GroupMemberListData.h"

static int ddLogLevel = DDLogLevelVerbose;

@interface BJIMEngine()
{
    NSInteger _pollingIndex;
    NSInteger _heatBeatIndex;
    BOOL _bIsPollingRequesting;
}

@property (nonatomic, strong) BJTimer *pollingTimer;
@property (nonatomic, strong) NSArray *im_polling_delta;
@property (nonatomic, strong) NSMutableArray *registerErrorCodeList;
@end

@implementation BJIMEngine

- (instancetype)init
{
    self = [super init];
    if (self)
    {
       self.im_polling_delta = @[@2, @4, @6, @8, @10];
    }
    return self;
}

- (void)start
{
    _engineActive = YES;
    _bIsPollingRequesting = NO;
    [self resetPollingIndex];
    [self nextPollingAt];
    [self.pollingTimer.timer fire];
}

- (void)stop
{
    _engineActive = NO;
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)syncConfig
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSyncConfig:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            SyncConfigModel *model = [MTLJSONAdapter modelOfClass:[SyncConfigModel class] fromJSONDictionary:result.dictionaryData error:&error];
            weakSelf.im_polling_delta = model.polling_delta;
            [weakSelf.syncConfigDelegate onSyncConfig:model];
        }
        else
        {
            DDLogWarn(@"Sync Config Fail [url:%@][params:%@]", params.url, params.urlPostParams);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Sync Config Fail [%@]", error.userInfo);
        
    }];
}

- (void)syncContacts
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesGetContactSucc:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            MyContactsModel *model = [MTLJSONAdapter modelOfClass:[MyContactsModel class] fromJSONDictionary:result.dictionaryData error:&error];
            if (weakSelf.synContactDelegate)
            {
                [weakSelf.synContactDelegate didSyncContacts:model];
            }
        }
        else
        {
            DDLogWarn(@"Sync Contacts Fail [url:%@][params:%@]", params.url, params.urlPostParams);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Sync Contact Fail [%@]", error.userInfo);
    }];
}

- (void)postMessage:(IMMessage *)message
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSendMessage:message succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error ;
            SendMsgModel *model = [MTLJSONAdapter modelOfClass:[SendMsgModel class] fromJSONDictionary:result.dictionaryData error:&error];
            [weakSelf.postMessageDelegate onPostMessageSucc:message result:model];
        }
        else
        {
            [self callbackErrorCode:result.code errMsg:result.msg];
            NSError *error = [[NSError alloc] initWithDomain:params.url code:result.code userInfo:@{@"msg":result.msg}];
            [weakSelf.postMessageDelegate onPostMessageFail:message error:error];
            DDLogWarn(@"Post Message Fail[url:%@][msg:%@]", params.url, params.urlPostParams);
        }
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Post Message Fail [url:%@][%@]", params.url, error.userInfo);
        NSError *_error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:@{@"msg":@"网络异常,请检查网络连接"}];
        [weakSelf.postMessageDelegate onPostMessageFail:message error:_error];
    }];
}

- (void)postMessageAchive:(IMMessage *)message
{
    __WeakSelf__ weakSelf = self;
    if (message.msg_t == eMessageType_IMG)
    {
        [NetWorkTool hermesStorageUploadImage:message succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
            NSError *error;
            BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
            if (result != nil && result.code == RESULT_CODE_SUCC)
            {
                PostAchiveModel *model = [MTLJSONAdapter modelOfClass:[PostAchiveModel class] fromJSONDictionary:result.dictionaryData error:&error];
                [weakSelf.postMessageDelegate onPostMessageAchiveSucc:message result:model];
            }
            else
            {
                NSError *error = [[NSError alloc] initWithDomain:params.url code:result.code userInfo:@{@"msg":result.msg}];
                [weakSelf.postMessageDelegate onPostMessageFail:message error:error];
                DDLogWarn(@"Post Message Achive Fail[url:%@][msg:%@]", params.url, params.urlPostParams);
                [self callbackErrorCode:result.code errMsg:result.msg];
            }
        } failure:^(NSError *error, RequestParams *params) {
            NSError *_error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:@{@"msg":@"网络异常,请检查网络连接"}];
            [weakSelf.postMessageDelegate onPostMessageFail:message error:_error];
        }];
    }
    else if (message.msg_t == eMessageType_AUDIO)
    {
        [NetWorkTool hermesStorageUploadAudio:message succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
            NSError *error;
            BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
            if (result != nil && result.code == RESULT_CODE_SUCC)
            {
                PostAchiveModel *model = [MTLJSONAdapter modelOfClass:[PostAchiveModel class] fromJSONDictionary:result.dictionaryData error:&error];
                [weakSelf.postMessageDelegate onPostMessageAchiveSucc:message result:model];
            }
            else
            {
                NSError *error = [[NSError alloc] initWithDomain:params.url code:result.code userInfo:@{@"msg":result.msg}];
                [weakSelf.postMessageDelegate onPostMessageFail:message error:error];
                DDLogWarn(@"Post Message Achive Fail[url:%@][msg:%@]", params.url, params.urlPostParams);
                [self callbackErrorCode:result.code errMsg:result.msg];
            }
        } failure:^(NSError *error, RequestParams *params) {
            NSError *_error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:@{@"msg":@"网络异常,请检查网络连接"}];
            [weakSelf.postMessageDelegate onPostMessageFail:message error:_error];
        }];
    }
}

- (void)postPollingRequest:(int64_t)max_user_msg_id
           excludeUserMsgs:(NSString *)excludeUserMsgs
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesPostPollingRequestUserLastMsgId:max_user_msg_id excludeUserMsgIds:excludeUserMsgs group_last_msg_ids:group_last_msg_ids currentGroup:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        _bIsPollingRequesting = NO;
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            PollingResultModel *model = [MTLJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.dictionaryData error:nil];
            if (weakSelf.pollingDelegate)
            {
                [weakSelf.pollingDelegate onPollingFinish:model];
            }
            if ([model.msgs count] > 0)
            {
                [weakSelf resetPollingIndex];
            }
            
            if ([model.ops count] > 0)
            {
                // 联系人有改变，刷新联系人
                if ([model.ops[0] integerValue] == 1)
                {
                    [weakSelf syncContacts];
                }
            }
            
            if ([[IMEnvironment shareInstance] isCurrentChatToGroup] || [[IMEnvironment shareInstance] isCurrentChatToUser])
            {
                [weakSelf resetPollingIndex];
            }
            
            
            [weakSelf nextPollingAt];
        }
        else
        {
            DDLogWarn(@"Post Polling Fail [url:%@][msg:%@]", params.url, params.urlPostParams);
            [weakSelf nextPollingAt];
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        _bIsPollingRequesting = NO;
        DDLogError(@"Post Polling Request Fail[url:%@][%@]", params.url, error.userInfo);
        [weakSelf nextPollingAt];
    }];

}

- (void)getMsgConversation:(NSInteger)conversationId minMsgId:(NSString *)eid groupId:(int64_t)groupId userId:(int64_t)userId excludeIds:(NSString *)excludeIds startMessageId:(NSString *)startMessageId
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesGetMsg:[eid longLongValue] groupId:groupId uid:userId excludeMsgIds:excludeIds succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if(result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            PollingResultModel *model = [MTLJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.dictionaryData error:&error];
            [weakSelf.getMsgDelegate onGetMsgSucc:conversationId minMsgId:eid newEndMessageId:startMessageId result:model];
        }
        else
        {
            DDLogWarn(@"Get MSG FAIL [url:%@][%@]", params.url, params.urlPostParams);
            [weakSelf.getMsgDelegate onGetMsgFail:conversationId minMsgId:eid];
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Get MSG FAIL [url:%@][%@]", params.url, error.userInfo);
        [weakSelf.getMsgDelegate onGetMsgFail:conversationId minMsgId:eid];
    }];
}

- (void)postChangeRemarkName:(NSString *)remarkName
                      userId:(int64_t)userId
                    userRole:(IMUserRole)userRole
                    callback:(void(^)(NSString *remarkName, NSString *remarkHeader, NSInteger errCode, NSString *errMsg))callback
{
    [NetWorkTool hermesChangeRemarkNameUserId:userId userRole:userRole remarkName:remarkName succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error ;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            callback(remarkName, [result.data valueForKey:@"remark_header"], result.code, result.msg);
        }
        else
        {
            callback(remarkName, nil, result.code, result.msg);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        callback(remarkName, nil, error.code, @"网络异常,请检查网络连接");
    }];
}

- (void)postGetUserInfo:(int64_t)userId
                   role:(IMUserRole)userRole
               callback:(void (^)(User *))callback
{
    [NetWorkTool hermesGetUserInfo:userId role:userRole succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:result.dictionaryData error:&error];
            callback(user);
        }
        else
        {
            callback(nil);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        callback(nil);
    }];
}

- (void)postGetGroupProfile:(int64_t)groupId callback:(void (^)(Group *))callback
{
    [NetWorkTool hermesGetGroupProfile:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            Group *group = [MTLJSONAdapter modelOfClass:[Group class] fromJSONDictionary:result.dictionaryData error:&error];
            callback(group);
        }
        else
        {
            callback(nil);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        callback(nil);
    }];
}


- (void)nextPollingAt
{
    _heatBeatIndex = 0;
    _pollingIndex = (MIN([self.im_polling_delta count] - 1, _pollingIndex + 1)) % [self.im_polling_delta count];
}

- (void)handlePollingEvent
{
    if (! [self isEngineActive]) {
        return;
    }
    
    if (_bIsPollingRequesting) return;
    
    _heatBeatIndex ++ ;
    _heatBeatIndex = MAX(0, MIN(_heatBeatIndex, [self.im_polling_delta[_pollingIndex] integerValue]));
    if (_heatBeatIndex != [self.im_polling_delta[_pollingIndex] integerValue])
        return;
    
    if (self.postMessageDelegate == nil)
    {
        [self nextPollingAt];
    }
    else
    {
        _bIsPollingRequesting = YES;
        [self.pollingDelegate onShouldStartPolling];
    }
}

- (void)resetPollingIndex
{
    _heatBeatIndex = 0;
    _pollingIndex = -1;
}

- (BJTimer *)pollingTimer
{
    if (_pollingTimer == nil)
    {
        _pollingTimer = [BJTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handlePollingEvent) forMode:NSRunLoopCommonModes];
    }
    
    return _pollingTimer;
}

#pragma mark - Group manager
- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback
{
    [NetWorkTool hermesLeaveGroupWithGroupId:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
            callback(nil);
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)postDisBandGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback
{
    [NetWorkTool hermesDisbandGroupWithGroupId:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
            callback(nil);
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)postChangeGroupName:(int64_t)groupId newName:(NSString *)name callback:(void (^)(NSError *err))callback
{
    [NetWorkTool hermesChangeGroupNameWithGroupId:groupId newName:name succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
            callback(nil);
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];

}

- (void)postSetGroupMsg:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status callback:(void (^)(NSError *err))callback
{
    [NetWorkTool hermesSetGroupMsgWithGroupId:groupId msgStatus:status succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
            callback(nil);
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];
    
}

- (void)postGetGroupMembersWithModel:(GetGroupMemberModel *)model callback:(void (^)(GroupMemberListData *members, NSError *err))callback
{
    [NetWorkTool hermesGetGroupMemberWithModel:model succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
        {
            GroupMemberListData *members = [MTLJSONAdapter modelOfClass:[GroupMemberListData class] fromJSONDictionary:result.dictionaryData error:&error];
            members.page = model.page;
            members.groupId = model.groupId;
            members.userRole = model.userRole;
            callback(members, error);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(nil, error);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        if (callback) {
            callback(nil, error);
        }
    }];
}

- (void)postGetGroupMembers:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index callback:(void (^)(GroupMemberListData *members, NSError *err))callback
{
    [NetWorkTool hermesGetGroupMemberWithGroupId:groupId userRole:userRole page:index succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
        {
            GroupMemberListData *members = [MTLJSONAdapter modelOfClass:[GroupMemberListData class] fromJSONDictionary:result.dictionaryData error:&error];
            members.page = index;
            members.groupId = groupId;
            members.userRole = userRole;
            callback(members, error);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(nil, error);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
        if (callback) {
            callback(nil, error);
        }
    }];
}

- (void)postSetGroupPush:(int64_t)groupId pushStatus:(IMGroupPushStatus)stauts callback:(void (^)(NSError *))callback
{
    [NetWorkTool hermesSetGroupPushStatusWithGroupId:groupId pushStatus:stauts succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
        {
            callback(error);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
       if (callback)
       {
           callback(nil);
       }
    }];
}

- (void)registerErrorCode:(IMErrorType)code
{
    [self.registerErrorCodeList addObject:@(code)];
}

- (void)unregisterErrorCode:(IMErrorType)code
{
    [self.registerErrorCodeList removeObject:@(code)];
}

- (void)callbackErrorCode:(NSInteger)errCode  errMsg:(NSString *)errMsg
{
    for (NSInteger index = 0; index < [self.registerErrorCodeList count]; ++ index)
    {
        if (errCode == [[self.registerErrorCodeList objectAtIndex:index] integerValue])
        {
            if (self.errCodeFilterCallback)
            {
                self.errCodeFilterCallback(errCode, errMsg);
            }
        }
    }
}

- (NSMutableArray *)registerErrorCodeList
{
    if (_registerErrorCodeList == nil)
    {
        _registerErrorCodeList = [[NSMutableArray alloc] init];
    }
    return _registerErrorCodeList;
}

@end
