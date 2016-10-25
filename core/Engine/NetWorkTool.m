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
#define HERMES_API_MY_CONTACTS [NSString stringWithFormat:@"%@/hermes/getMyContacts", HOST_API]
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

//user
#define HERMES_API_SET_USER_INFO [NSString stringWithFormat:@"%@/hermes/setUserInfo", HOST_API]
#define HERMES_API_GET_USER_ONLINE_STATUS [NSString stringWithFormat:@"%@/hermes/getUserOnlineStatus", HOST_API]

#import "GetGroupMemberModel.h"

@implementation NetWorkTool

+ (void)hermesSyncConfig:(BJCNOnSuccess)succ
                                    failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SYNC_CONFIG method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
    
}

+ (void)hermesSendMessage:(IMMessage *)message
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
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
    
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesGetContactSucc:(BJCNOnSuccess)succ failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_MY_CONTACTS method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesPostPollingRequestUserLastMsgId:(int64_t)last_user_msg_id
                                               excludeUserMsgIds:(NSString *)excludeUserMsgIds
                                              group_last_msg_ids:(NSString *)group_last_msg_ids
                                                    currentGroup:(int64_t)groupId
                                                            succ:(BJCNOnSuccess)succ
                                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
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
    
    [NetWorkTool insertCommonParams:requestParams];
 
//    DDLogInfo(@"[Post Polling][url:%@][%@]", [requestParams url], [requestParams urlPostParams]);
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesGetMsg:(int64_t)eid
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
        return;
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
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesStorageUploadImage:(IMMessage *)message
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    IMImgMessageBody *messageBody = (IMImgMessageBody *)message.messageBody;
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_UPLOAD_IMAGE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    NSString *filename = [NSString stringWithFormat:@"hermes-%lf.jpg", [[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", [BJCFFileManagerTool libraryDir] ,messageBody.file];
    [requestParams appendFile:filePath mimeType:@"image/*" filename:filename forKey:@"attachment"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doUploadResource:requestParams success:succ failure:false progress:nil];
}

+ (void)hermesStorageUploadAudio:(IMMessage *)message
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
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doUploadResource:requestParams success:succ failure:false progress:nil];
}

+ (void)hermesChangeRemarkNameUserId:(int64_t)userId
                                               userRole:(IMUserRole)userRole
                                             remarkName:(NSString *)remarkName
                                                   succ:(BJCNOnSuccess)succ
                                                failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_CHANGE_REMARK_NAME method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [requestParmas appendPostParamValue:remarkName forKey:@"remark_name"];
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}


+ (void)hermesGetUserInfo:(int64_t)userId
                                        role:(IMUserRole)userRole
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_USER_INFO method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesGetGroupProfile:(int64_t)groupId
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_PROFILE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:@"1" forKey:@"group_auth"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesGetGroupDetail:(int64_t)groupId
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_DETAIL method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesGetGroupMembers:(int64_t)groupId
                                           page:(NSInteger)page
                                       pageSize:(NSInteger)pageSize
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", page] forKey:@"page"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", pageSize] forKey:@"page_size"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesTransferGroup:(int64_t)groupId
                                   transfer_id:(int64_t)transfer_id
                                 transfer_role:(int64_t)transfer_role
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_TRANSFERGROUP method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", transfer_id] forKey:@"transfer_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", transfer_role] forKey:@"transfer_role"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesSetGroupAvatar:(int64_t)groupId
                                         avatar:(int64_t)avatar
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_SETGROUPAVATAR method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", avatar] forKey:@"avatar"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesSetGroupNameAvatar:(int64_t)groupId
                                          groupName:(NSString*)groupName
                                             avatar:(int64_t)avatar
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_SETGROUPNameAVATAR method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:groupName forKey:@"group_name"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", avatar] forKey:@"avatar"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesSetGroupAdmin:(int64_t)groupId
                                   user_number:(int64_t)user_number
                                     user_role:(int64_t)user_role
                                        status:(int64_t)status
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_SETADMIN method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_number] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_role] forKey:@"user_role"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", status] forKey:@"status"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesRemoveGroupMember:(int64_t)groupId
                                       user_number:(int64_t)user_number
                                         user_role:(int64_t)user_role
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_REMOVEMEMBER method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_number] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", user_role] forKey:@"user_role"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesGetGroupFiles:(int64_t)groupId
                            last_file_id:(int64_t)last_file_id
                                    succ:(BJCNOnSuccess)succ
                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_LISTFILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", last_file_id] forKey:@"last_file_id"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

//+ (NSOperationQueue *)getGroupFileUploadQueue
//{
//    static AFHTTPRequestOperationManager *_uploadManager = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _uploadManager = [AFHTTPRequestOperationManager manager];
//        _uploadManager.operationQueue.maxConcurrentOperationCount = 1;
//    });
//    return _uploadManager;
//}

+ (void)hermesUploadGroupFile:(NSString*)attachment
                              filePath:(NSString*)filePath
                              fileName:(NSString*)fileName
                               success:(BJCNOnSuccess)success
                               failure:(BJCNOnFailure)failure
                              progress:(BJCNOnProgress)progress
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_UPLOAD_GROUP_FILE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:attachment forKey:@"attachment"];
    [requestParams appendFile:filePath mimeType:attachment filename:fileName forKey:@"attachment"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doUploadResource:requestParams success:success failure:failure progress:progress];
    
}

+ (void)hermesUploadFaceImage:(NSString *)fileName
                                        filePath:(NSString *)filePath
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_UPLOAD_IMAGE method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendFile:filePath mimeType:@"image/*" filename:fileName forKey:@"attachment"];
   [NetWorkTool insertCommonParams:requestParams];
//    return [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
    [BJCNNetworkUtilInstance doUploadResource:requestParams success:succ failure:failure progress:nil];
}

+ (void)hermesAddGroupFile:(int64_t)groupId
                                   storage_id:(int64_t)storage_id
                                     fileName:(NSString*)fileName
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_ADD_GROUP_FILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", storage_id] forKey:@"storage_id"];
    [requestParams appendPostParamValue:fileName forKey:@"filename"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

//+ (NSOperationQueue *)getGroupFileDownloadQueue
//{
//    static AFHTTPRequestOperationManager *_downloadManager = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _downloadManager = [AFHTTPRequestOperationManager manager];
//        _downloadManager.operationQueue.maxConcurrentOperationCount = 1;
//    });
//    return _downloadManager;
//}


+ (void)hermesDownloadGroupFile:(NSString*)fileUrl
                                filePath:(NSString*)filePath
                                 success:(BJCNOnSuccess)success
                                 failure:(BJCNOnFailure)failure
                                progress:(BJCNOnProgress)progress
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:fileUrl method:kBJCNHttpMethod_GET];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doDownloadResource:fileUrl fileDownPath:filePath success:success failure:failure progress:progress];
}

+ (void)hermesPreviewGroupFile:(int64_t)groupId
                                          file_id:(int64_t)file_id
                                             succ:(BJCNOnSuccess)succ
                                          failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_PREVIEW_GROUP_FILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", file_id] forKey:@"file_id"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesDeleteGroupFile:(int64_t)groupId
                                         file_id:(int64_t)file_id
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_DELETE_GROUP_FILE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", file_id] forKey:@"file_id"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesCreateGroupNotice:(int64_t)groupId
                                           content:(NSString*)content
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_CREATE_GROUP_NOTICE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:content forKey:@"content"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesGetGroupNotice:(int64_t)groupId
                                        last_id:(int64_t)last_id
                                      page_size:(int64_t)page_size
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_NOTICE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", last_id] forKey:@"last_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", page_size] forKey:@"page_size"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesRemoveGroupNotice:(int64_t)notice_id
                                          group_id:(int64_t)group_id
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_REMOVE_GROUP_NOTICE method:kBJCNHttpMethod_GET];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", notice_id] forKey:@"notice_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", group_id] forKey:@"group_id"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesAddBlacklist:(int64_t)userId
                                     userRole:(IMUserRole)userRole
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure;
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_ADD_BLACKLIST method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesCancelBlacklist:(int64_t)userId
                                        userRole:(IMUserRole)userRole
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_CANCEL_BLACKLIST method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

+ (void)hermesAddRecentContactId:(int64_t)userId
                                               role:(IMUserRole)userRole
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_ADD_RECENT_CONTACT method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
}

#pragma mark - Group set

+ (void)hermesLeaveGroupWithGroupId:(int64_t)groupId
                                                  succ:(BJCNOnSuccess)succ
                                               failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_LEAVE_GROUP method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (void)hermesDisbandGroupWithGroupId:(int64_t)groupId
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_DISBAND_GROUP method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
   [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (void)hermesGetGroupMemberWithModel:(GetGroupMemberModel *)model
                                                      succ:(BJCNOnSuccess)succ
                                                   failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", model.groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lu",(unsigned long)model.page] forKey:@"page"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)model.pageSize] forKey:@"page_size"];
    if (model.groupId != eUserRole_Anonymous) {
        [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)model.userRole] forKey:@"user_role"];
    }
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (void)hermesGetGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_GROUP_MEMBERS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lu",(unsigned long)index] forKey:@"page"];
    [requestParmas appendPostParamValue:@"20" forKey:@"page_size"];
    if (userRole != eUserRole_Anonymous) {
        [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)userRole] forKey:@"user_role"];
    }
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (void)hermesChangeGroupNameWithGroupId:(int64_t)groupId newName:(NSString *)name
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SET_GROUP_NAME method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:name forKey:@"group_name"];
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (void)hermesSetGroupMsgWithGroupId:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SET_MSG_STATUS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)status] forKey:@"msg_status"];
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (void)hermesSetGroupPushStatusWithGroupId:(int64_t)groupId pushStatus:(IMGroupPushStatus)status
                                                          succ:(BJCNOnSuccess)succ
                                                       failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        failure(nil, nil);
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SET_PUSH_STATUS method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParmas appendPostParamValue:[NSString stringWithFormat:@"%ld",(long)status] forKey:@"push_status"];
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:succ failure:failure];
}

+ (void)insertCommonParams:(BJCNRequestParams *)requestParms
{
    [requestParms appendPostParamValue:@"im_version" forKey:[[IMEnvironment shareInstance] getCurrentVersion]];
}

+ (void)hermesSetUserName:(NSString *)userName userAvatar:(NSString *)userAvatar
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        return;
    }
    BJCNRequestParams *requestParmas = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_SET_USER_INFO method:kBJCNHttpMethod_POST];
    [requestParmas appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParmas appendPostParamValue:userName  forKey:@"user_name"];
    [requestParmas appendPostParamValue:userAvatar forKey:@"user_avatar"];
    [NetWorkTool insertCommonParams:requestParmas];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParmas success:nil failure:nil];
}


+ (void)hermesGetUserOnlineStatus:(int64_t)userId
                             role:(IMUserRole)userRole
                             succ:(BJCNOnSuccess)succ
                          failure:(BJCNOnFailure)failure
{
    if (! [[IMEnvironment shareInstance] isLogin])
    {
        return;
    }
    BJCNRequestParams *requestParams = [[BJCNRequestParams alloc] initWithUrl:HERMES_API_GET_USER_ONLINE_STATUS method:kBJCNHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", userId] forKey:@"user_number"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)userRole] forKey:@"user_role"];
    [NetWorkTool insertCommonParams:requestParams];
    [BJCNNetworkUtilInstance doNetworkRequest:requestParams success:succ failure:failure];
    
}

@end
