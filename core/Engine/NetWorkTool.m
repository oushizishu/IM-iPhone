//
//  NetTool.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "NetWorkTool.h"
#import <BJHL-Common-iOS-SDK/BJFileManagerTool.h>
#import "NSDictionary+Json.h"
#import <AFNetworking.h>

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
#define HERMES_API_GET_GROUP_LISTFILE [NSString stringWithFormat:@"%@/group/listFile", HOST_API]
#define HERMES_API_UPLOAD_GROUP_FILE [NSString stringWithFormat:@"%@/storage/uploadFile", HOST_API]
#define HERMES_API_ADD_GROUP_FILE [NSString stringWithFormat:@"%@/group/addFile", HOST_API]
#define HERMES_API_PREVIEW_GROUP_FILE [NSString stringWithFormat:@"%@/group/previewFile", HOST_API]
#define HERMES_API_DELETE_GROUP_FILE [NSString stringWithFormat:@"%@/group/deleteFile", HOST_API]
#define HERMES_API_CREATE_GROUP_NOTICE [NSString stringWithFormat:@"%@/hermes/createGroupNotice", HOST_API]
#define HERMES_API_GET_GROUP_NOTICE [NSString stringWithFormat:@"%@/hermes/getGroupNotice", HOST_API]
#define HERMES_API_REMOVE_GROUP_NOTICE [NSString stringWithFormat:@"%@/hermes/removeGroupNotice", HOST_API]

#define HERMES_API_GET_ADD_ATTENTION [NSString stringWithFormat:@"%@/focus/addFocus", HOST_API]
#define HERMES_API_GET_CANCEL_ATTENTION [NSString stringWithFormat:@"%@/focus/removeFocus", HOST_API]
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

+ (BJNetRequestOperation *)hermesSyncConfig:(onSuccess)succ
                                    failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_SYNC_CONFIG method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
    
}

+ (BJNetRequestOperation *)hermesSendMessage:(IMMessage *)message
                                        succ:(onSuccess)succ
                                     failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_SEND_MESSAGE method:kHttpMethod_POST];
    
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
    
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation*)hermesGetContactSucc:(onSuccess)succ failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_MY_CONTACTS method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesPostPollingRequestUserLastMsgId:(int64_t)last_user_msg_id
                                               excludeUserMsgIds:(NSString *)excludeUserMsgIds
                                              group_last_msg_ids:(NSString *)group_last_msg_ids
                                                    currentGroup:(int64_t)groupId
                                                            succ:(onSuccess)succ
                                                         failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_POLLING method:kHttpMethod_POST];
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
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetMsg:(int64_t)eid
                                groupId:(int64_t)groupId
                                    uid:(int64_t)uid
                               userRole:(IMUserRole)userRole
                          excludeMsgIds:(NSString *)excludeMsgIds
                                   succ:(onSuccess)succ
                                failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_MSG method:kHttpMethod_POST];
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
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesStorageUploadImage:(IMMessage *)message
                                               succ:(onSuccess)succ
                                            failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    IMImgMessageBody *messageBody = (IMImgMessageBody *)message.messageBody;
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_UPLOAD_IMAGE method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    NSString *filename = [NSString stringWithFormat:@"hermes-%lf.jpg", [[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", [BJFileManagerTool libraryDir] ,messageBody.file];
    [requestParams appendFile:filePath mimeType:@"image/*" filename:filename forKey:@"attachment"];
    
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesStorageUploadAudio:(IMMessage *)message
                                               succ:(onSuccess)succ
                                            failure:(onFailure)failure
{
    IMAudioMessageBody *messageBody = (IMAudioMessageBody *)message.messageBody;
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_UPLOAD_AUDIO method:kHttpMethod_POST];
    [requestParams  appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", messageBody.length] forKey:@"length"];
    NSString *filename = [NSString stringWithFormat:@"hermes-%lf.mp3", [[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", [BJFileManagerTool libraryDir] ,messageBody.file];
    [requestParams appendFile:filePath mimeType:@"audio/mp3" filename:filename forKey:@"attachment"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesChangeRemarkNameUserId:(int64_t)userId
                                               userRole:(IMUserRole)userRole
                                             remarkName:(NSString *)remarkName
                                                   succ:(onSuccess)succ
                                                failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_GET_CHANGE_REMARK_NAME method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [requestParmas appendPostParamValue:remarkName forKey:@"remark_name"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}


+ (BJNetRequestOperation *)hermesGetUserInfo:(int64_t)userId
                                        role:(IMUserRole)userRole
                                        succ:(onSuccess)succ
                                     failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_USER_INFO method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetGroupProfile:(int64_t)groupId
                                            succ:(onSuccess)succ
                                         failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_PROFILE method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:@"1" forKey:@"group_auth"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetGroupDetail:(int64_t)groupId
                                           succ:(onSuccess)succ
                                        failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_DETAIL method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetGroupMembers:(int64_t)groupId
                                           page:(NSInteger)page
                                       pageSize:(NSInteger)pageSize
                                           succ:(onSuccess)succ
                                        failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", page] forKey:@"page"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", pageSize] forKey:@"page_size"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetGroupFiles:(int64_t)groupId
                            last_file_id:(int64_t)last_file_id
                                    succ:(onSuccess)succ
                                 failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_LISTFILE method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", last_file_id] forKey:@"last_file_id"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
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

+ (NSOperation *)doNetworkRequest:(RequestParams *)requestParams
                                    success:(onSuccess)success
                                    failure:(onFailure)failure
                                      retry:(onRetryRequest)retry
                                   progress:(onProgress)progress
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
    
    if (requestParams.httpMethod == kHttpMethod_GET)
    {
        //Get
        NSError *error = nil;
        request = [manager.requestSerializer requestWithMethod:@"GET" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams error:&error];
    }
    else if (requestParams.httpMethod == kHttpMethod_POST)
    {
        //Post
        NSError *error = nil;
        request = [manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            NSArray *allKeys = requestParams.fileParams.allKeys;
            for (NSString *key in allKeys) {
                FileWrapper *wrapper = [requestParams.fileParams objectForKey:key];
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
            
            BJNetRequestOperation *op = [weakSelf doNetworkRequest:requestParams success:success failure:failure retry:retry progress:progress];
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
    return operation;
}

+ (NSOperation *)hermesUploadGroupFile:(NSString*)attachment
                              filePath:(NSString*)filePath
                              fileName:(NSString*)fileName
                               success:(onSuccess)success
                               failure:(onFailure)failure
                              progress:(onProgress)progress
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_UPLOAD_GROUP_FILE method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:attachment forKey:@"attachment"];
    [requestParams appendFile:filePath mimeType:attachment filename:fileName forKey:@"attachment"];
    
    return [self doNetworkRequest:requestParams success:success failure:failure retry:nil progress:progress];
}

+ (BJNetRequestOperation *)hermesAddGroupFile:(int64_t)groupId
                                   storage_id:(int64_t)storage_id
                                     fileName:(NSString*)fileName
                                         succ:(onSuccess)succ
                                      failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_ADD_GROUP_FILE method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", storage_id] forKey:@"storage_id"];
    [requestParams appendPostParamValue:fileName forKey:@"filename"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
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

+ (BJNetRequestOperation *)doDownloadResource:(RequestParams *)requestParams
                                 fileDownPath:(NSString *)filePath
                                      success:(onSuccess)success
                                        retry:(onRetryRequest)retry
                                      failure:(onFailure)failure
                                     progress:(onProgress)progress
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
            BJNetRequestOperation *op = [weakSelf doDownloadResource:requestParams fileDownPath:filePath success:success retry:retry failure:failure progress:progress];
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
    return operation;
}

+ (NSOperation *)hermesDownloadGroupFile:(NSString*)fileUrl
                                filePath:(NSString*)filePath
                                 success:(onSuccess)success
                                 failure:(onFailure)failure
                                progress:(onProgress)progress
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:fileUrl method:kHttpMethod_GET];
    return [self doDownloadResource:requestParams fileDownPath:filePath success:success retry:nil failure:failure progress:progress];
}

+ (BJNetRequestOperation *)hermesPreviewGroupFile:(int64_t)groupId
                                          file_id:(int64_t)file_id
                                             succ:(onSuccess)succ
                                          failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_PREVIEW_GROUP_FILE method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", file_id] forKey:@"file_id"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesDeleteGroupFile:(int64_t)groupId
                                         file_id:(int64_t)file_id
                                            succ:(onSuccess)succ
                                         failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_DELETE_GROUP_FILE method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", file_id] forKey:@"file_id"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesCreateGroupNotice:(int64_t)groupId
                                           content:(NSString*)content
                                              succ:(onSuccess)succ
                                           failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_CREATE_GROUP_NOTICE method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:content forKey:@"content"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetGroupNotice:(int64_t)groupId
                                        last_id:(int64_t)last_id
                                      page_size:(int64_t)page_size
                                           succ:(onSuccess)succ
                                        failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_NOTICE method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", last_id] forKey:@"last_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", page_size] forKey:@"page_size"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesRemoveGroupNotice:(int64_t)notice_id
                                              succ:(onSuccess)succ
                                           failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_REMOVE_GROUP_NOTICE method:kHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", notice_id] forKey:@"notice_id"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}


+ (BJNetRequestOperation *)hermesAddAttention:(int64_t)userId
                                     userRole:(IMUserRole)userRole
                                         succ:(onSuccess)succ
                                      failure:(onFailure)failure;
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_ADD_ATTENTION method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesCancelAttention:(int64_t)userId
                                        userRole:(IMUserRole)userRole
                                            succ:(onSuccess)succ
                                         failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_CANCEL_ATTENTION method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesAddBlacklist:(int64_t)userId
                                     userRole:(IMUserRole)userRole
                                         succ:(onSuccess)succ
                                      failure:(onFailure)failure;
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_ADD_BLACKLIST method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesCancelBlacklist:(int64_t)userId
                                        userRole:(IMUserRole)userRole
                                            succ:(onSuccess)succ
                                         failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_CANCEL_BLACKLIST method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesAddRecentContactId:(int64_t)userId
                                               role:(IMUserRole)userRole
                                               succ:(onSuccess)succ
                                            failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_ADD_RECENT_CONTACT method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

#pragma mark - Group set

+ (BJNetRequestOperation *)hermesLeaveGroupWithGroupId:(int64_t)groupId
                                                  succ:(onSuccess)succ
                                               failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_LEAVE_GROUP method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesDisbandGroupWithGroupId:(int64_t)groupId
                                                    succ:(onSuccess)succ
                                                 failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_DISBAND_GROUP method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetGroupMemberWithModel:(GetGroupMemberModel *)model
                                                      succ:(onSuccess)succ
                                                   failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", model.groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lu",(unsigned long)model.page] forKey:@"page"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)model.pageSize] forKey:@"page_size"];
    if (model.groupId != eUserRole_Anonymous) {
        [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)model.userRole] forKey:@"user_role"];
    }
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index
                                                    succ:(onSuccess)succ
                                                 failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lu",(unsigned long)index] forKey:@"page"];
    [requestParmas appendPostParamValue:@"20" forKey:@"page_size"];
    if (userRole != eUserRole_Anonymous) {
        [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)userRole] forKey:@"user_role"];
    }
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesChangeGroupNameWithGroupId:(int64_t)groupId newName:(NSString *)name
                                                    succ:(onSuccess)succ
                                                 failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_SET_GROUP_NAME method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:name forKey:@"group_name"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesSetGroupMsgWithGroupId:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status
                                                    succ:(onSuccess)succ
                                                 failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_SET_MSG_STATUS method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)status] forKey:@"msg_status"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesSetGroupPushStatusWithGroupId:(int64_t)groupId pushStatus:(IMGroupPushStatus)status
                                                          succ:(onSuccess)succ
                                                       failure:(onFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return nil;
    }
    RequestParams *requestParmas = [[RequestParams alloc] initWithUrl:HERMES_API_SET_PUSH_STATUS method:kHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)status] forKey:@"push_status"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParmas success:succ failure:failure];
}
@end
