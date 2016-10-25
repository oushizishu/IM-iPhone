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
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDLegacyMacros.h>
#import "GroupMemberListData.h"
#import "LimitQueue.h"

#import <BJHL-Foundation-iOS/BJHL-Foundation-iOS.h>
#import <BJHL-Network-iOS/BJHL-Network-iOS.h>
#import "IMJSONAdapter.h"

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
    [NetWorkTool hermesGetContactSucc:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            MyContactsModel *model = [IMJSONAdapter modelOfClass:[MyContactsModel class] fromJSONDictionary:result.dictionaryData error:&error];
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
        
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
        [NetWorkTool hermesStorageUploadImage:message succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
            NSError *error;
            BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
            if (result != nil && result.code == RESULT_CODE_SUCC)
            {
                PostAchiveModel *model = [IMJSONAdapter modelOfClass:[PostAchiveModel class] fromJSONDictionary:result.dictionaryData error:&error];
                [weakSelf.postMessageDelegate onPostMessageAchiveSucc:message result:model];
            }
            else
            {
                NSError *error = [[NSError alloc] initWithDomain:params.url code:result.code userInfo:@{@"msg":result.msg}];
                [weakSelf.postMessageDelegate onPostMessageFail:message error:error];
                DDLogWarn(@"Post Message Achive Fail[url:%@][msg:%@]", params.url, params.urlPostParams);
                [self callbackErrorCode:result.code errMsg:result.msg];
            }
        } failure:^(NSError *error, BJCNRequestParams *params) {
            NSError *_error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:@{@"msg":@"网络异常,请检查网络连接"}];
            [weakSelf.postMessageDelegate onPostMessageFail:message error:_error];
        }];
    }
    else if (message.msg_t == eMessageType_AUDIO)
    {
        [NetWorkTool hermesStorageUploadAudio:message succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
            NSError *error;
            BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
            if (result != nil && result.code == RESULT_CODE_SUCC)
            {
                PostAchiveModel *model = [IMJSONAdapter modelOfClass:[PostAchiveModel class] fromJSONDictionary:result.dictionaryData error:&error];
                [weakSelf.postMessageDelegate onPostMessageAchiveSucc:message result:model];
            }
            else
            {
                NSError *error = [[NSError alloc] initWithDomain:params.url code:result.code userInfo:@{@"msg":result.msg}];
                [weakSelf.postMessageDelegate onPostMessageFail:message error:error];
                DDLogWarn(@"Post Message Achive Fail[url:%@][msg:%@]", params.url, params.urlPostParams);
                [self callbackErrorCode:result.code errMsg:result.msg];
            }
        } failure:^(NSError *error, BJCNRequestParams *params) {
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
              isFirstGetMsg:(BOOL)isFirstGetMsg
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NetWorkTool hermesGetMsg:[lastMessageId longLongValue] groupId:groupId uid:userId userRole:userRole excludeMsgIds:excludeIds succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if(result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            PollingResultModel *model = [IMJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.dictionaryData error:&error];
            [weakSelf.getMsgDelegate onGetMsgSuccMinMsgId:lastMessageId userId:userId userRole:userRole groupId:groupId result:model isFirstGetMsg:isFirstGetMsg];
        }
        else
        {
            DDLogWarn(@"Get MSG FAIL [url:%@][%@]", params.url, params.urlPostParams);
            [weakSelf.getMsgDelegate onGetMsgFailMinMsgId:lastMessageId userId:userId userRole:userRole groupId:groupId isFirstGetMsg:isFirstGetMsg];
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, BJCNRequestParams *params) {
        DDLogError(@"Get MSG FAIL [url:%@][%@]", params.url, error.userInfo);
        [weakSelf.getMsgDelegate onGetMsgFailMinMsgId:lastMessageId userId:userId userRole:userRole groupId:groupId isFirstGetMsg:isFirstGetMsg];
        
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
    [NetWorkTool hermesChangeRemarkNameUserId:userId userRole:userRole remarkName:remarkName succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        
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
            [weakSelf callbackErrorCode:result.code errMsg:result.msg];
        }
        
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(remarkName, nil, error.code, @"网络异常,请检查网络连接");
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postGetUserOnLineStatus:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(IMUserOnlieStatusResult *result))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesGetUserOnlineStatus:userId role:userRole succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC) {
            IMUserOnlieStatusResult *data = [IMJSONAdapter modelOfClass:[IMUserOnlieStatusResult class] fromJSONDictionary:result.data error:&error];
            callback(data);
        }
        else
        {
            callback(nil);
            [weakSelf callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(nil);
    }];
}

- (void)postGetUserInfo:(int64_t)userId
                   role:(IMUserRole)userRole
               callback:(void (^)(User *))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesGetUserInfo:userId role:userRole succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            User *user = [IMJSONAdapter modelOfClass:[User class] fromJSONDictionary:result.dictionaryData error:&error];
            callback(user);
        }
        else
        {
            callback(nil);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(nil);
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)postGetGroupProfile:(int64_t)groupId callback:(void (^)(Group *))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesGetGroupProfile:groupId succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            Group *group = [IMJSONAdapter modelOfClass:[Group class] fromJSONDictionary:result.dictionaryData error:&error];
            callback(group);
        }
        else
        {
            callback(nil);
            [self callbackErrorCode:result.code errMsg:result.msg];
            
            
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(nil);
        
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
    }];
}

- (void)getGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback
{
    __WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesGetGroupDetail:groupId succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            GroupDetail *groupDetail = [IMJSONAdapter modelOfClass:[GroupDetail class] fromJSONDictionary:result.dictionaryData error:&error];
            callback(nil,groupDetail);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,nil);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,nil);
    }];
}

- (void)getGroupMembers:(int64_t)groupId page:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void(^)(NSError *error ,NSArray *members,BOOL hasMore,BOOL is_admin,BOOL is_major))callback
{
    __WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesGetGroupMembers:groupId page:page pageSize:pageSize succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            NSArray *members = [IMJSONAdapter modelsOfClass:[GroupDetailMember class] fromJSONArray:[result.data  objectForKey:@"list"] error:&error];
            BOOL hasMore = [[result.data objectForKey:@"has_more"] boolValue];
            BOOL is_admin = [[result.data objectForKey:@"is_admin"] boolValue];
            BOOL is_major = [[result.data objectForKey:@"is_major"] boolValue];
            callback(nil,members,hasMore,is_admin,is_major);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,nil,0,0,0);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,nil,0,0,0);
    }];
}

- (void)transferGroup:(int64_t)groupId
          transfer_id:(int64_t)transfer_id
        transfer_role:(int64_t)transfer_role
             callback:(void(^)(NSError *error))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesTransferGroup:groupId transfer_id:transfer_id transfer_role:transfer_role succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            callback(nil);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if(callback)
        {
            callback(error);
        }
    }];
}

- (void)setGroupAvatar:(int64_t)groupId
                avatar:(int64_t)avatar
              callback:(void(^)(NSError *error))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSetGroupAvatar:groupId avatar:avatar succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            callback(nil);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if(callback)
        {
            callback(error);
        }
    }];
}

- (void)setGroupNameAvatar:(int64_t)groupId
                 groupName:(NSString*)groupName
                    avatar:(int64_t)avatar
                  callback:(void(^)(NSError *error))callback
{
    [NetWorkTool hermesSetGroupNameAvatar:groupId groupName:groupName avatar:avatar succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            callback(nil);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if(callback)
        {
            callback(error);
        }
    }];
}

- (void)setGroupAdmin:(int64_t)groupId
          user_number:(int64_t)user_number
            user_role:(int64_t)user_role
               status:(int64_t)status
             callback:(void(^)(NSError *error))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSetGroupAdmin:groupId user_number:user_number user_role:user_role status:status succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            callback(nil);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if(callback)
        {
            callback(error);
        }
    }];
}

- (void)removeGroupMember:(int64_t)groupId
              user_number:(int64_t)user_number
                user_role:(int64_t)user_role
                 callback:(void(^)(NSError *error))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesRemoveGroupMember:groupId user_number:user_number user_role:user_role succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            callback(nil);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if(callback)
        {
            callback(error);
        }
    }];
}

- (void)getGroupFiles:(int64_t)groupId
         last_file_id:(int64_t)last_file_id
             callback:(void(^)(NSError *error ,NSArray<GroupFile *> *list))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesGetGroupFiles:groupId last_file_id:last_file_id succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            GroupListFile *listFile = [IMJSONAdapter modelOfClass:[GroupListFile class] fromJSONDictionary:result.data error:&error];
            callback(nil,listFile.list);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,nil);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,nil);
    }];
}

- (void)uploadGroupFile:(NSString*)attachment
                                 filePath:(NSString*)filePath
                                 fileName:(NSString*)fileName
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
                                 progress:(BJCNOnProgress)progress
{
    __WeakSelf__ weakSelf = self;
        
    [NetWorkTool hermesUploadGroupFile:attachment filePath:filePath fileName:fileName success:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params){
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            int64_t storage_id = [[result.data objectForKey:@"id"] longLongValue];
            NSString *storage_url = [result.data objectForKey:@"url"];
            callback(nil,storage_id,storage_url);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,nil,nil);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
         callback(error,nil,nil);
    } progress:progress];
}

- (void)uploadImageFile:(NSString*)fileName
                                 filePath:(NSString*)filePath
                                 callback:(void(^)(NSError *error ,int64_t storage_id,NSString *storage_url))callback
{
    [NetWorkTool hermesUploadFaceImage:fileName filePath:filePath succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            int64_t storage_id = [[result.data objectForKey:@"id"] longLongValue];
            NSString *storage_url = [result.data objectForKey:@"url"];
            callback(nil,storage_id,storage_url);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,0,nil);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,0,nil);
    }];
}

- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback
{
    __WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesAddGroupFile:groupId storage_id:storage_id fileName:fileName succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            GroupFile *groupFile = [IMJSONAdapter modelOfClass:[GroupFile class] fromJSONDictionary:[result.data objectForKey:@"file"] error:&error];
            callback(nil,groupFile);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,nil);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,nil);
    }];
}

- (void)downloadGroupFile:(NSString*)fileUrl
                                   filePath:(NSString*)filePath
                                   callback:(void(^)(NSError *error))callback
                                   progress:(BJCNOnProgress)progress
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesDownloadGroupFile:fileUrl filePath:filePath success:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        callback(nil);
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error);
    } progress:progress];
}

- (void)previewGroupFile:(int64_t)groupId
                 file_id:(int64_t)file_id
                callback:(void(^)(NSError *error ,NSString *url))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesPreviewGroupFile:groupId file_id:file_id succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            NSString *url = [result.data objectForKey:@"url"];
            callback(nil,url);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,nil);
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,nil);
    }];
}

- (void)setGroupMsgStatus:(int64_t)status
                  groupId:(int64_t)groupId
                 callback:(void(^)(NSError *error))callback
{
    __WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesSetGroupMsgWithGroupId:groupId msgStatus:status succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        
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
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)deleteGroupFile:(int64_t)groupId
                file_id:(int64_t)file_id
               callback:(void(^)(NSError *error))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesDeleteGroupFile:groupId file_id:file_id succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
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
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];
}

-(void)createGroupNotice:(int64_t)groupId
                 content:(NSString*)content
                callback:(void(^)(NSError *error))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesCreateGroupNotice:groupId content:content succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
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
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];

}

-(void)getGroupNotice:(int64_t)groupId
              last_id:(int64_t)last_id
            page_size:(int64_t)page_size
             callback:(void(^)(NSError *error ,BOOL isAdmin ,NSArray<GroupNotice*> *list ,BOOL hasMore))callback
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesGetGroupNotice:groupId last_id:last_id page_size:page_size succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (result != nil && [result.data isKindOfClass:[NSDictionary class]] && result.code == RESULT_CODE_SUCC)
        {
            BOOL isAdmin = [[result.data objectForKey:@"is_admin"] boolValue];
            NSArray<GroupNotice *> *list = [IMJSONAdapter modelsOfClass:[GroupNotice class] fromJSONArray:[result.data objectForKey:@"notice_list"] error:&error];
            BOOL hasMore = [[result.data objectForKey:@"has_more"] boolValue];
            callback(nil,isAdmin,list,hasMore);
        }
        else
        {
            if (!error) {
                error = [NSError bjim_errorWithReason:result.msg code:result.code];
            }
            callback(error,NO,nil,NO);
        }

    } failure:^(NSError *error, BJCNRequestParams *params) {
        if (callback) {
            callback(error, NO,nil,NO);
        }
    }];
}

-(void)removeGroupNotice:(int64_t)notice_id
                group_id:(int64_t)group_id
                callback:(void(^)(NSError *error))callback
{
    [NetWorkTool hermesRemoveGroupNotice:notice_id group_id:group_id succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
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
        }
    } failure:^(NSError *error, BJCNRequestParams *params) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)postAddBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    //__WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesAddBlacklist:userId userRole:userRole succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        callback(nil,result);
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,nil);
    }];
}

- (void)postCancelBlacklist:(int64_t)userId role:(IMUserRole)userRole callback:(void(^)(NSError *error ,BaseResponse *result))callback
{
    //__WeakSelf__ weakSelf = self;
    
    [NetWorkTool hermesCancelBlacklist:userId userRole:userRole succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        callback(nil,result);
    } failure:^(NSError *error, BJCNRequestParams *params) {
        callback(error,nil);
    }];
}

#pragma mark - Group manager
- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback
{
    __WeakSelf__ weakSelf = self;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [NetWorkTool hermesLeaveGroupWithGroupId:groupId succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
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
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
    
    [NetWorkTool hermesDisbandGroupWithGroupId:groupId succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        
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
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
    
    [NetWorkTool hermesChangeGroupNameWithGroupId:groupId newName:name succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
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
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
    
    [NetWorkTool hermesSetGroupMsgWithGroupId:groupId msgStatus:status succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
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
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
    [NetWorkTool hermesGetGroupMemberWithModel:model succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
        {
            GroupMemberListData *members = [IMJSONAdapter modelOfClass:[GroupMemberListData class] fromJSONDictionary:result.dictionaryData error:&error];
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
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
    [NetWorkTool hermesGetGroupMemberWithGroupId:groupId userRole:userRole page:index succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        [weakSelf recordHttpRequestTime:endTime - startTime];
        NSError *error;
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
        if (!error && result.code == RESULT_CODE_SUCC)
        {
            GroupMemberListData *members = [IMJSONAdapter modelOfClass:[GroupMemberListData class] fromJSONDictionary:result.dictionaryData error:&error];
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
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
    [NetWorkTool hermesSetGroupPushStatusWithGroupId:groupId pushStatus:stauts succ:^(id response, NSDictionary *responseHeaders, BJCNRequestParams *params) {
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
    } failure:^(NSError *error, BJCNRequestParams *params) {
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
    [self.httpUsingTimeQueue offer:@(time)];
}

- (NSTimeInterval)getAverageRequestTime
{
    NSArray *array = [_httpUsingTimeQueue toArray];
    if (array.count < 10) return 0;
    NSTimeInterval sum = 0;
    for (NSInteger index = 0; index < array.count; ++ index) {
        sum += [[array objectAtIndex:index] doubleValue];
    }

    return sum/array.count;
}
@end
