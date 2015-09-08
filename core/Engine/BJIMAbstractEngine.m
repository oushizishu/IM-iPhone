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

static int ddLogLevel = DDLogLevelVerbose;

@interface BJIMAbstractEngine()
@property (nonatomic, strong) NSMutableArray *registerErrorCodeList;
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


- (void)syncConfig
{
    NSAssert(0, @"请重载这个方法");
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
    NSAssert(0, @"请重载这个方法");
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

- (void)postPullRequest:(int64_t)max_user_msg_id
           excludeUserMsgs:(NSString *)excludeUserMsgs
          groupsLastMsgIds:(NSString *)group_last_msg_ids
              currentGroup:(int64_t)groupId
{
    NSAssert(0, @"请重载这个方法");
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

@end
