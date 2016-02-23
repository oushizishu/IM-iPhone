//
//  NetTool.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "NetWorkTool.h"
#import "NSDictionary+Json.h"
#import <AFNetworking.h>

#import <BJHL-Foundation-iOS/BJHL-Foundation-iOS.h>

#define HOST_APIS @[@"http://dev01-hermes.genshuixue.com", @"http://beta-hermes.genshuixue.com", @"http://hermes.genshuixue.com"]
#define HOST_API HOST_APIS[[IMEnvironment shareInstance].debugMode]

#define HERMES_API_SYNC_CONFIG [NSString stringWithFormat:@"%@/hermes/syncConfig", HOST_API]
#define HERMES_API_MY_CONTACTS [NSString stringWithFormat:@"%@/hermes/myContacts", HOST_API]
#define HERMES_API_SEND_MESSAGE [NSString stringWithFormat:@"%@/hermes/sendMsg", HOST_API]
#define HERMES_API_POLLING [NSString stringWithFormat:@"%@/hermes/polling", HOST_API]
#define HERMES_API_GET_MSG [NSString stringWithFormat:@"%@/hermes/getMsg", HOST_API]
#define HERMES_API_UPLOAD_IMAGE [NSString stringWithFormat:@"%@/storage/uploadImage", HOST_API]
#define HERMES_API_UPLOAD_AUDIO [NSString stringWithFormat:@"%@/storage/uploadAudio", HOST_API]
#define HERMES_API_GET_CHANGE_REMARK_NAME [NSString stringWithFormat:@"%@/hermes/setRemarkName", HOST_API]
#define HERMES_API_GET_USER_INFO [NSString stringWithFormat:@"%@/hermes/getUserInfo", HOST_API]
#define HERMES_API_GET_GROUP_PROFILE [NSString stringWithFormat:@"%@/hermes/getGroupProfile", HOST_API]

#define HERMES_API_GET_GROUP_DETAIL [NSString stringWithFormat:@"%@/hermes/getGroupProfile2", HOST_API]
#define HERMES_API_GET_GROUP_MEMBERS [NSString stringWithFormat:@"%@/hermes/getGroupMembers", HOST_API]
#define HERMES_API_GET_GROUP_TRANSFERGROUP [NSString stringWithFormat:@"%@/hermes/transferGroup", HOST_API]
#define HERMES_API_GET_GROUP_SETGROUPAVATAR [NSString stringWithFormat:@"%@/hermes/setGroupAvatar", HOST_API]
#define HERMES_API_GET_GROUP_SETGROUPNameAVATAR [NSString stringWithFormat:@"%@/group/setNameAvatar", HOST_API]
#define HERMES_API_GET_GROUP_SETADMIN [NSString stringWithFormat:@"%@/group/setAdmin", HOST_API]
#define HERMES_API_GET_GROUP_REMOVEMEMBER [NSString stringWithFormat:@"%@/group/removeMember", HOST_API]
#define HERMES_API_GET_GROUP_LISTFILE [NSString stringWithFormat:@"%@/group/listFile", HOST_API]
#define HERMES_API_UPLOAD_GROUP_FILE [NSString stringWithFormat:@"%@/storage/uploadFile", HOST_API]
#define HERMES_API_ADD_GROUP_FILE [NSString stringWithFormat:@"%@/group/addFile", HOST_API]
#define HERMES_API_PREVIEW_GROUP_FILE [NSString stringWithFormat:@"%@/group/previewFile", HOST_API]
#define HERMES_API_DELETE_GROUP_FILE [NSString stringWithFormat:@"%@/group/deleteFile", HOST_API]
#define HERMES_API_CREATE_GROUP_NOTICE [NSString stringWithFormat:@"%@/hermes/createGroupNotice", HOST_API]
#define HERMES_API_GET_GROUP_NOTICE [NSString stringWithFormat:@"%@/hermes/getGroupNotice", HOST_API]
#define HERMES_API_REMOVE_GROUP_NOTICE [NSString stringWithFormat:@"%@/hermes/removeGroupNotice", HOST_API]

#define HERMES_API_GET_ADD_BLACKLIST [NSString stringWithFormat:@"%@/hermes/addBlack", HOST_API]
#define HERMES_API_GET_CANCEL_BLACKLIST [NSString stringWithFormat:@"%@/hermes/removeBlack", HOST_API]
#define HERMES_API_ADD_RECENT_CONTACT [NSString stringWithFormat:@"%@/hermes/addRecentContact", HOST_API]

//群组
#define HERMES_API_SET_GROUP_NAME [NSString stringWithFormat:@"%@/hermes/setGroupName", HOST_API]
#define HERMES_API_SET_MSG_STATUS [NSString stringWithFormat:@"%@/hermes/setMsgStatus", HOST_API]
#define HERMES_API_SET_PUSH_STATUS [NSString stringWithFormat:@"%@/hermes/setPushStatus", HOST_API]
#define HERMES_API_LEAVE_GROUP [NSString stringWithFormat:@"%@/hermes/quitGroup", HOST_API]
#define HERMES_API_DISBAND_GROUP [NSString stringWithFormat:@"%@/hermes/dissolveGroup", HOST_API]

#import "GetGroupMemberModel.h"

@implementation NetWorkTool

+ (BJCNNetRequestOperation *)hermesSyncConfig:(BJCNOnSuccess)succ
                                    failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SYNC_CONFIG method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
    
}

+ (BJCNNetRequestOperation *)hermesSendMessage:(IMMessage *)message
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SEND_MESSAGE method:kBJCNHttpMethod_POST];
    
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", message.sender] forKey:@"sender"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)message.senderRole] forKey:@"sender_r"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", message.receiver] forKey:@"receiver"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.receiverRole] forKey:@"receiver_r"];
    [requestParams appendPostParamValue:message.messageBody.description forKey:@"body"];
    if (message.ext != nil) {
        
        NSString *ext = [message.ext jsonString];
        if (ext)
            [requestParams appendPostParamValue:ext forKey:@"ext"];
    }
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.chat_t] forKey:@"chat_t"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.msg_t] forKey:@"msg_t"];
    [requestParams appendPostParamValue:message.sign forKey:@"sign"];
    
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation*)hermesGetContactSucc:(BJCNOnSuccess)succ failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_MY_CONTACTS method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesPostPollingRequestUserLastMsgId:(int64_t)last_user_msg_id
                                               excludeUserMsgIds:(NSString *)excludeUserMsgIds
                                              group_last_msg_ids:(NSString *)group_last_msg_ids
                                                    currentGroup:(int64_t)groupId
                                                            succ:(BJCNOnSuccess)succ
                                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_POLLING method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", last_user_msg_id] forKey:@"user_last_msg_id"];
    if ([excludeUserMsgIds length] > 0)
    {
        [requestParams appendPostParamValue:excludeUserMsgIds forKey:@"exclude_msg_ids"];
    }
    if ([group_last_msg_ids length] > 0)
    {
        [requestParams appendPostParamValue:group_last_msg_ids forKey:@"groups_last_msg_id"];
    }
    
    if (groupId > 0)
    {
        [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"current_group_id"];
    }
    
 
//    DDLogInfo(@"[Post Polling][url:%@][%@]", [requestParams url], [requestParams urlPostParams]);
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetMsg:(int64_t)eid
                                groupId:(int64_t)groupId
                                    uid:(int64_t)uid
                               userRole:(IMUserRole)userRole
                          excludeMsgIds:(NSString *)excludeMsgIds
                                   succ:(BJCNOnSuccess)succ
                                failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_MSG method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", eid] forKey:@"eid"];
    
    if (groupId > 0) {
        [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    } else {
        [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld",uid] forKey:@"user_number"];
        [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    }
    
    if ([excludeMsgIds length] > 0)
    {
        [requestParams appendPostParamValue:excludeMsgIds forKey:@"exclude_msgs"];
    }
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesStorageUploadImage:(IMMessage *)message
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    IMImgMessageBody *messageBody = (IMImgMessageBody *)message.messageBody;
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_UPLOAD_IMAGE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    NSString *filename = [NSString stringWithFormat:@"hermes-%lf.jpg", [[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", [BJCFFileManagerTool libraryDir] ,messageBody.file];
    [requestParams appendFile:filePath mimeType:@"image/*" filename:filename forKey:@"attachment"];
    
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesStorageUploadAudio:(IMMessage *)message
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure
{
    IMAudioMessageBody *messageBody = (IMAudioMessageBody *)message.messageBody;
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_UPLOAD_AUDIO method:kBJCNHttpMethod_POST];
    [requestParams  appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", messageBody.length] forKey:@"length"];
    NSString *filename = [NSString stringWithFormat:@"hermes-%lf.mp3", [[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", [BJCFFileManagerTool libraryDir] ,messageBody.file];
    [requestParams appendFile:filePath mimeType:@"audio/mp3" filename:filename forKey:@"attachment"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesChangeRemarkNameUserId:(int64_t)userId
                                               userRole:(IMUserRole)userRole
                                             remarkName:(NSString *)remarkName
                                                   succ:(BJCNOnSuccess)succ
                                                failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_CHANGE_REMARK_NAME method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [requestParmas appendPostParamValue:remarkName forKey:@"remark_name"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}


+ (BJCNNetRequestOperation *)hermesGetUserInfo:(int64_t)userId
                                        role:(IMUserRole)userRole
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_USER_INFO method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetGroupProfile:(int64_t)groupId
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_PROFILE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:@"1" forKey:@"group_auth"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetGroupDetail:(int64_t)groupId
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_DETAIL method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetGroupMembers:(int64_t)groupId
                                           page:(NSInteger)page
                                       pageSize:(NSInteger)pageSize
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", page] forKey:@"page"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", pageSize] forKey:@"page_size"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesTransferGroup:(int64_t)groupId
                                   transfer_id:(int64_t)transfer_id
                                 transfer_role:(int64_t)transfer_role
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_TRANSFERGROUP method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", transfer_id] forKey:@"transfer_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", transfer_role] forKey:@"transfer_role"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesSetGroupAvatar:(int64_t)groupId
                                         avatar:(int64_t)avatar
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_SETGROUPAVATAR method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", avatar] forKey:@"avatar"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesSetGroupNameAvatar:(int64_t)groupId
                                          groupName:(NSString*)groupName
                                             avatar:(int64_t)avatar
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_SETGROUPNameAVATAR method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:groupName forKey:@"group_name"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", avatar] forKey:@"avatar"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesSetGroupAdmin:(int64_t)groupId
                                   user_number:(int64_t)user_number
                                     user_role:(int64_t)user_role
                                        status:(int64_t)status
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_SETADMIN method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_number] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_role] forKey:@"user_role"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", status] forKey:@"status"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesRemoveGroupMember:(int64_t)groupId
                                       user_number:(int64_t)user_number
                                         user_role:(int64_t)user_role
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_REMOVEMEMBER method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_number] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_role] forKey:@"user_role"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetGroupFiles:(int64_t)groupId
                            last_file_id:(int64_t)last_file_id
                                    succ:(BJCNOnSuccess)succ
                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_LISTFILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", last_file_id] forKey:@"last_file_id"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (NSOperationQueue *)getGroupFileUploadQueue
{
    static AFHTTPRequestOperationManager *_uploadManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _uploadManager = [AFHTTPRequestOperationManager manager];
        _uploadManager.operationQueue.maxConcurrentOperationCount = 1;
    });
    return _uploadManager;
}

+ (BJCNNetRequestOperation *)doNetworkRequest:(BJCNRequestParams *)requestParams
                                    success:(BJCNOnSuccess)success
                                    failure:(BJCNOnFailure)failure
                                      retry:(BJCNOnRetryRequest)retry
                                   progress:(BJCNOnProgress)progress
{
    AFHTTPRequestOperationManager *manager = [self getGroupFileUploadQueue];
    //https
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    //response
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
    responseSerializer.removesKeysWithNullValues = YES;
    
    NSMutableSet *contentTypes = [NSMutableSet setWithSet:responseSerializer.acceptableContentTypes];
    [contentTypes addObject:@"text/plain"];
    responseSerializer.acceptableContentTypes = contentTypes;
    
    manager.responseSerializer = responseSerializer;
    
    //request
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setTimeoutInterval:requestParams.requestTimeOut];
    
    NSMutableURLRequest *request = nil;
    
    if (requestParams.httpMethod == kBJCNHttpMethod_GET)
    {
        //Get
        NSError *error = nil;
        request = [manager.requestSerializer requestWithMethod:@"GET" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams error:&error];
    }
    else if (requestParams.httpMethod == kBJCNHttpMethod_POST)
    {
        //Post
        NSError *error = nil;
        request = [manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            NSArray *allKeys = requestParams.fileParams.allKeys;
            for (NSString *key in allKeys) {
                BJCNFileWrapper *wrapper = [requestParams.fileParams objectForKey:key];
                NSURL *fileUrl = [NSURL fileURLWithPath:wrapper.filePath];
                NSError *error = nil;
                [formData appendPartWithFileURL:fileUrl name:key fileName:wrapper.fileName mimeType:wrapper.mimeType error:&error];
            }
        } error:&error];
    }
    
    NSDate *__date = [NSDate date];
    //request headers
    request.allHTTPHeaderFields = requestParams.requestHeaders;
    
    __weak typeof(self) weakSelf = self;
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (success && ![operation isCancelled])
        {
            success(responseObject, operation.response.allHeaderFields, requestParams);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (requestParams.maxRetryCount > 0)
        {
            requestParams.maxRetryCount --;
            
            BJCNNetRequestOperation *op = [weakSelf doNetworkRequest:requestParams success:success failure:failure retry:retry progress:progress];
            if (retry)
            {
                retry(error, requestParams, op);
            }
            return ;
        }
        if (failure && ![operation isCancelled])
        {
            failure(error, requestParams);
        }
    }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (progress)
        {
            progress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }
    }];
    
    [manager.operationQueue addOperation:operation];
    return [[BJCNNetRequestOperation alloc] initWithHttpOperation:operation];
}

+ (BJCNNetRequestOperation *)hermesUploadGroupFile:(NSString*)attachment
                              filePath:(NSString*)filePath
                              fileName:(NSString*)fileName
                               success:(BJCNOnSuccess)success
                               failure:(BJCNOnFailure)failure
                              progress:(BJCNOnProgress)progress
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_UPLOAD_GROUP_FILE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:attachment forKey:@"attachment"];
    [requestParams appendFile:filePath mimeType:attachment filename:fileName forKey:@"attachment"];
    
    return [self doNetworkRequest:requestParams success:success failure:failure retry:nil progress:progress];
}

+ (BJCNNetRequestOperation *)hermesUploadFaceImage:(NSString *)fileName
                                        filePath:(NSString *)filePath
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_UPLOAD_IMAGE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendFile:filePath mimeType:@"image/*" filename:fileName forKey:@"attachment"];
    
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesAddGroupFile:(int64_t)groupId
                                   storage_id:(int64_t)storage_id
                                     fileName:(NSString*)fileName
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_ADD_GROUP_FILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", storage_id] forKey:@"storage_id"];
    [requestParams appendPostParamValue:fileName forKey:@"filename"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (NSOperationQueue *)getGroupFileDownloadQueue
{
    static AFHTTPRequestOperationManager *_downloadManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [AFHTTPRequestOperationManager manager];
        _downloadManager.operationQueue.maxConcurrentOperationCount = 1;
    });
    return _downloadManager;
}

+ (BJCNNetRequestOperation *)doDownloadResource:(BJCNRequestParams *)requestParams
                                 fileDownPath:(NSString *)filePath
                                      success:(BJCNOnSuccess)success
                                        retry:(BJCNOnRetryRequest)retry
                                      failure:(BJCNOnFailure)failure
                                     progress:(BJCNOnProgress)progress
{
    AFHTTPRequestOperationManager *manager = [self getGroupFileDownloadQueue];
    //https
    manager.securityPolicy.allowInvalidCertificates = YES;
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    // timeout
    [requestSerializer setTimeoutInterval:requestParams.requestTimeOut];
    
    NSError *error = nil;
    NSURLRequest *request = [requestSerializer requestWithMethod:@"GET" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams error:&error];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.securityPolicy.allowInvalidCertificates = YES;
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (progress)
        {
            progress(bytesRead, totalBytesRead, totalBytesExpectedToRead);
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success && ![operation isCancelled])
        {
            success(responseObject, operation.response.allHeaderFields, requestParams);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (requestParams.maxRetryCount > 0)
        {
            requestParams.maxRetryCount -- ;
            BJCNNetRequestOperation *op = [weakSelf doDownloadResource:requestParams fileDownPath:filePath success:success retry:retry failure:failure progress:progress];
            if (retry)
            {
                retry(error, requestParams, op);
            }
            return ;
        }
        if (failure && ![operation isCancelled])
        {
            failure(error, requestParams);
        }
    }];
    
    [manager.operationQueue addOperation:operation];
    return [[BJCNNetRequestOperation alloc] initWithHttpOperation:operation];
}

+ (BJCNNetRequestOperation *)hermesDownloadGroupFile:(NSString*)fileUrl
                                filePath:(NSString*)filePath
                                 success:(BJCNOnSuccess)success
                                 failure:(BJCNOnFailure)failure
                                progress:(BJCNOnProgress)progress
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:fileUrl method:kBJCNHttpMethod_GET];
    return [self doDownloadResource:requestParams fileDownPath:filePath success:success retry:nil failure:failure progress:progress];
}

+ (BJCNNetRequestOperation *)hermesPreviewGroupFile:(int64_t)groupId
                                          file_id:(int64_t)file_id
                                             succ:(BJCNOnSuccess)succ
                                          failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_PREVIEW_GROUP_FILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", file_id] forKey:@"file_id"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesDeleteGroupFile:(int64_t)groupId
                                         file_id:(int64_t)file_id
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_DELETE_GROUP_FILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", file_id] forKey:@"file_id"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesCreateGroupNotice:(int64_t)groupId
                                           content:(NSString*)content
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_CREATE_GROUP_NOTICE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:content forKey:@"content"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetGroupNotice:(int64_t)groupId
                                        last_id:(int64_t)last_id
                                      page_size:(int64_t)page_size
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_NOTICE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", last_id] forKey:@"last_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", page_size] forKey:@"page_size"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesRemoveGroupNotice:(int64_t)notice_id
                                          group_id:(int64_t)group_id
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_REMOVE_GROUP_NOTICE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", notice_id] forKey:@"notice_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", group_id] forKey:@"group_id"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesAddBlacklist:(int64_t)userId
                                     userRole:(IMUserRole)userRole
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure;
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_ADD_BLACKLIST method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesCancelBlacklist:(int64_t)userId
                                        userRole:(IMUserRole)userRole
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_CANCEL_BLACKLIST method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesAddRecentContactId:(int64_t)userId
                                               role:(IMUserRole)userRole
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_ADD_RECENT_CONTACT method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

#pragma mark - Group set

+ (BJCNNetRequestOperation *)hermesLeaveGroupWithGroupId:(int64_t)groupId
                                                  succ:(BJCNOnSuccess)succ
                                               failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_LEAVE_GROUP method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesDisbandGroupWithGroupId:(int64_t)groupId
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_DISBAND_GROUP method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetGroupMemberWithModel:(GetGroupMemberModel *)model
                                                      succ:(BJCNOnSuccess)succ
                                                   failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", model.groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lu",(unsigned long)model.page] forKey:@"page"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)model.pageSize] forKey:@"page_size"];
    if (model.groupId != eUserRole_Anonymous) {
        [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)model.userRole] forKey:@"user_role"];
    }
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesGetGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lu",(unsigned long)index] forKey:@"page"];
    [requestParmas appendPostParamValue:@"20" forKey:@"page_size"];
    if (userRole != eUserRole_Anonymous) {
        [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)userRole] forKey:@"user_role"];
    }
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesChangeGroupNameWithGroupId:(int64_t)groupId newName:(NSString *)name
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SET_GROUP_NAME method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:name forKey:@"group_name"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesSetGroupMsgWithGroupId:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SET_MSG_STATUS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)status] forKey:@"msg_status"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJCNNetRequestOperation *)hermesSetGroupPushStatusWithGroupId:(int64_t)groupId pushStatus:(IMGroupPushStatus)status
                                                          succ:(BJCNOnSuccess)succ
                                                       failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SET_PUSH_STATUS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)status] forKey:@"push_status"];
    return [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}
@end
