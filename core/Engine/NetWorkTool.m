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

@implementation NetWorkTool

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
    [requestParams appendPostParamValue:message.body forKey:@"body"];
    if (message.ext != nil) {
        [requestParams appendPostParamValue:message.ext forKey:@"ext"];
    }
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.chat_t] forKey:@"chat_t"];
    [requestParams appendPostParamValue:[NSString stringWithFormat:@"%ld", message.msg_t] forKey:@"msg_t"];
    [requestParams appendPostParamValue:message.sign forKey:@"sign"];
    
    return [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:succ failure:failure];
}

@end
