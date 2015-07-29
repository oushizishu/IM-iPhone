//
//  NetTool.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "NetWorkTool.h"

#define HOST_APIS @[@"http://test-hermes.genshuixue.com", @"http://beta-hermes.genshuixue.com", @"http://hermes.genshuixue.com"]
#define HOST_API HOST_APIS[[IMEnvironment shareInstance].debugMode]

#define HERMES_API_SYNC_CONFIG [NSString stringWithFormat:@"%@/hermes/syncConfig", HOST_API]
#define HERMES_API_MY_CONTACTS [NSString stringWithFormat:@"%@/hermes/myContacts", HOST_API]
#define HERMES_API_SEND_MESSAGE [NSString stringWithFormat:@"%@/hermes/sendMsg", HOST_API]
#define HERMES_API_POLLING [NSString stringWithFormat:@"%@/hermes/polling", HOST_API]
#define HERMES_API_GET_MSG [NSString stringWithFormat:@"%@/hermes/getMsg", HOST_API]
#define HERMES_API_UPLOAD_IMAGE [NSString stringWithFormat:@"%@/storage/uploadImage", HOST_API]
#define HERMES_API_UPLOAD_AUDIO [NSString stringWithFormat:@"%@/storage/uploadAudio", HOST_API]


@implementation NetWorkTool

+ (BJNetRequestOperation *)hermesSyncConfig:(onSuccess)succ
                                    failure:(onFailure)failure
{
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_SYNC_CONFIG method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
    
}

+ (BJNetRequestOperation *)hermesSendMessage:(IMMessage *)message
                                        succ:(onSuccess)succ
                                     failure:(onFailure)failure
{
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_SEND_MESSAGE method:kHttpMethod_POST];
    
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", message.sender] forKey:@"sender"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", (long)message.senderRole] forKey:@"sender_r"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", message.receiver] forKey:@"receiver"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.receiverRole] forKey:@"receiver_r"];
    [requestParams appendPostParamValue:message.messageBody.description forKey:@"body"];
    if (message.ext != nil) {
        [requestParams appendPostParamValue:message.ext.description forKey:@"ext"];
    }
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.chat_t] forKey:@"chat_t"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.msg_t] forKey:@"msg_t"];
    [requestParams appendPostParamValue:message.sign forKey:@"sign"];
    
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation*)hermesGetContactSucc:(onSuccess)succ failure:(onFailure)failure
{
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
    
 
    DDLogInfo(@"[Post Polling][url:%@][%@]", [requestParams url], [requestParams urlPostParams]);
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

+ (BJNetRequestOperation *)hermesGetMsg:(int64_t)eid
                                groupId:(int64_t)groupId
                                    uid:(int64_t)uid
                          excludeMsgIds:(NSString *)excludeMsgIds
                                   succ:(onSuccess)succ
                                failure:(onFailure)failure
{
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_GET_MSG method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", eid] forKey:@"eid"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld", groupId] forKey:@"group_id"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%lld",uid] forKey:@"uid"];
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
    IMImgMessageBody *messageBody = (IMImgMessageBody *)message.messageBody;
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:HERMES_API_UPLOAD_IMAGE method:kHttpMethod_POST];
    [requestParams appendPostParamValue:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    NSString *filename = [NSString stringWithFormat:@"hermes-%lf.jpg", [[NSDate date] timeIntervalSince1970]];
    [requestParams appendFile:messageBody.file mimeType:@"image/*" filename:filename forKey:@"attachment"];
    
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
    [requestParams appendFile:messageBody.file mimeType:@"audio/mp3" filename:filename forKey:@"attachment"];
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

@end
