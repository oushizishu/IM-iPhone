//
//  BJIMAbstractEngine.m
//  Pods
//
//  Created by 杨磊 on 15/9/8.
//
//

#import "BJIMAbstractEngine.h"
#import "NetWorkTool.h"
#import "BaseResponse.h"
#import "NSError+BJIM.h"
#import <BJHL-Common-iOS-SDK/BJCommonDefines.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDLegacyMacros.h>
#import "GroupMemberListData.h"
#import "LimitQueue.h"

static DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface BJIMAbstractEngine()
@property (nonatomic, strong) NSMutableArray *registerErrorCodeList;

@property (nonatomic, strong) LimitQueue *httpUsingTimeQueue; // 记录 50 个 http 请求消耗的时长，用于判断网络速率
@end

@implementation BJIMAbstractEngine

- (void)start 
{
    NSAssert(0, @"请重载这个方法");
}

- (void)stop
{
    NSAssert(0, @"请重载这个方法");
}


/**
 *  同步配置
 */
- (void)syncConfig
{
    NSAssert(0, @"请重载这个方法");
}

/**
 *  同步联系人，暂时统一走 http
 */
- (void)syncContacts
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesGetContactSucc:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
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
            [weakSelf callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Sync Contact Fail [%@]", error.userInfo);
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

/**
 *  发送消息
 *
 *  @param message <#message description#>
 */
- (void)postMessage:(IMMessage *)message
{
    NSAssert(0, @"请重载这个方法");
}

/**
 *  上传附件
 *
 *  @param message <#message description#>
 */
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

/**
 *  拉去消息
 *
 *  @param max_user_msg_id    当前单聊最大的消息Id
 *  @param excludeUserMsgs    不需要返回的消息ids
 *  @param group_last_msg_ids 每个群的最大消息id
 *  @param groupId            当前正在聊天的群id
 */
- (void)postPullRequest:(int64_t)max_user_msg_id
           excludeUserMsgs:(NSString *)excludeUserMsgs
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId
{
    NSAssert(0, @"请重载这个方法");
}

/**
 *  getMsg 加载更多消息
 *
 *  @param conversationId <#conversationId description#>
 *  @param eid            <#eid description#>
 *  @param groupId        <#groupId description#>
 *  @param userId         <#userId description#>
 *  @param excludeIds     <#excludeIds description#>
 *  @param startMessageId <#startMessageId description#>
 */
//- (void)getMsgConversation:(NSInteger)conversationId
//                  minMsgId:(NSString *)eid
//                   groupId:(int64_t)groupId
//                    userId:(int64_t)userId
//                excludeIds:(NSString *)excludeIds
//            startMessageId:(NSString *)startMessageId
- (void)postGetMsgLastMsgId:(NSString *)lastMessageId
                    groupId:(int64_t)groupId
                     userId:(int64_t)userId
                   userRole:(IMUserRole)userRole
                 excludeIds:(NSString *)excludeIds
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesGetMsg:[lastMessageId longLongValue] groupId:groupId uid:userId userRole:userRole excludeMsgIds:excludeIds succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if(result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            PollingResultModel *model = [MTLJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.dictionaryData error:&error];
            [weakSelf.getMsgDelegate onGetMsgSuccMinMsgId:lastMessageId userId:userId userRole:userRole groupId:groupId result:model];
        }
        else
        {
            DDLogWarn(@"Get MSG FAIL [url:%@][%@]", params.url, params.urlPostParams);
            [weakSelf.getMsgDelegate onGetMsgFailMinMsgId:lastMessageId userId:userId userRole:userRole groupId:groupId];
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        DDLogError(@"Get MSG FAIL [url:%@][%@]", params.url, error.userInfo);
        [weakSelf.getMsgDelegate onGetMsgFailMinMsgId:lastMessageId userId:userId userRole:userRole groupId:groupId];
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postChangeRemarkName:(NSString *)remarkName
                      userId:(int64_t)userId
                    userRole:(IMUserRole)userRole
                    callback:(void(^)(NSString *remarkName, NSString *remarkHeader, NSInteger errCode, NSString *errMsg))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesChangeRemarkNameUserId:userId userRole:userRole remarkName:remarkName succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
         NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
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
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postGetUserInfo:(int64_t)userId
                   role:(IMUserRole)userRole
               callback:(void (^)(User *))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesGetUserInfo:userId role:userRole succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
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
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postGetGroupProfile:(int64_t)groupId callback:(void (^)(Group *))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesGetGroupProfile:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
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
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postAddAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,User *user))callback
{
    //__WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesAddAttention:userId userRole:userRole succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
            NSError *error;
            BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
            User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:result.dictionaryData error:&error];
            callback(nil,user);
        } failure:^(NSError *error, RequestParams *params) {
            callback(nil,nil);
    }];
    
}

- (void)postCancelAttention:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,User *user))callback
{
    //__WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesCancelAttention:userId userRole:userRole succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:result.dictionaryData error:&error];
        callback(nil,user);
    } failure:^(NSError *error, RequestParams *params) {
        callback(nil,nil);
    }];
    
}

- (void)postAddBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,User *user))callback
{
    //__WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesAddBlacklist:userId userRole:userRole succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:result.dictionaryData error:&error];
        callback(nil,user);
    } failure:^(NSError *error, RequestParams *params) {
        callback(nil,nil);
    }];
}

- (void)postCancelBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,User *user))callback
{
    //__WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesCancelBlacklist:userId userRole:userRole succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:result.dictionaryData error:&error];
        callback(nil,user);
    } failure:^(NSError *error, RequestParams *params) {
        callback(nil,nil);
    }];
}

#pragma mark - Group manager
- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesLeaveGroupWithGroupId:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
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
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postDisBandGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesDisbandGroupWithGroupId:groupId succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
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
        
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postChangeGroupName:(int64_t)groupId newName:(NSString *)name callback:(void (^)(NSError *err))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
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
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    } failure:^(NSError *error, RequestParams *params) {
        if (callback) {
            callback(error);
        }
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
    
}

- (void)postSetGroupMsg:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status callback:(void (^)(NSError *err))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesSetGroupMsgWithGroupId:groupId msgStatus:status succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
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
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
    
}

- (void)postGetGroupMembersWithModel:(GetGroupMemberModel *)model callback:(void (^)(GroupMemberListData *members, NSError *err))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesGetGroupMemberWithModel:model succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
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
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postGetGroupMembers:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index callback:(void (^)(GroupMemberListData *members, NSError *err))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesGetGroupMemberWithGroupId:groupId userRole:userRole page:index succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
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
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postSetGroupPush:(int64_t)groupId pushStatus:(IMGroupPushStatus)stauts callback:(void (^)(NSError *))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesSetGroupPushStatusWithGroupId:groupId pushStatus:stauts succ:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
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
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}


#pragma mark - errorCode
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

- (LimitQueue *)httpUsingTimeQueue
{
    if (_httpUsingTimeQueue == nil)
    {
        //限长 50
        _httpUsingTimeQueue = [[LimitQueue alloc] initWithCapacity:50];
    }
    return _httpUsingTimeQueue;
}

- (void)recordHttpRequestTime:(NSTimeInterval)time
{
    [_httpUsingTimeQueue offer:@(time)];
}

- (NSTimeInterval)getAverageRequestTime
{
    NSArray *array = [_httpUsingTimeQueue toArray];
    if (array.count == 0) return 0;
    NSTimeInterval sum = 0;
    for (NSInteger index = 0; index < array.count; ++ index) {
        sum += [[array objectAtIndex:index] doubleValue];
    }

    return sum/array.count;
}
@end
