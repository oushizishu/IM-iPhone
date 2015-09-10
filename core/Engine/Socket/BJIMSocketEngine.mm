//
//  BJIMSocketEngine.m
//  Pods
//
//  Created by 杨磊 on 15/9/7.
//
//

#import "BJIMSocketEngine.h"
#import <BJHL-Common-iOS-SDK/BJCommonDefines.h>
#import <CocoaLumberjack/DDLegacyMacros.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NetWorkTool.h"
#import "BaseResponse.h"
#import "NSDictionary+Json.h"
#import "BJTimer.h"
#import "NSString+Json.h"
#import "NSError+BJIM.h"

static DDLogLevel ddLogLevel = DDLogLevelVerbose;

//request api
#define SOCKET_API_REQUEST_MESSAGE_SEND     @"message_send_req"
#define SOCKET_API_REQUEST_MESSAGE_PULL     @"message_pull_req"
#define SOCKET_API_REQUEST_LOGIN            @"session_record"
#define SOCKET_API_REQUEST_HEART_BEAT       @"heart_beat"

//response api
#define SOCKET_API_RESPONSE_MESSAGE_SEND    @"message_send_res"
#define SOCKET_API_RESPONSE_MESSAGE_PULL    @"message_pull_res"
#define SOCKET_API_RESPONSE_LOGIN           @"session_record_res"
#define SOCKET_API_RESPONSE_HEART_BEAT      @"heart_beat"
#define SOCKET_API_RESPONSE_MESSAGE_NEW     @"message_new"


@interface NSDictionary (SocketParams)

- (NSString *)socketParamsString;

@end

@implementation NSDictionary (SocketParams)

- (NSString *)socketParamsString
{
    NSMutableString *ret = [[NSMutableString alloc] init];
    NSArray *keys = [self allKeys];
    for (NSInteger index = 0; index < keys.count; ++ index)
    {
        id key = [keys objectAtIndex:index];
        [ret appendFormat:@"%@=%@", key, [self valueForKey:key]];
        if (index < (keys.count - 1)) {
            [ret appendFormat:@"&"];
        }
    }
    return ret;
}

@end

class IMSocketDelegate : public network::Delegate
{
public:
    BJIMSocketEngine *engine;
    virtual ~IMSocketDelegate();
    virtual void onOpen(network::WebSocketInterface* ws);
    virtual void onMessage(network::WebSocketInterface* ws, const network::Data& data);
    virtual void onClose(network::WebSocketInterface* ws);
    virtual void onError(network::WebSocketInterface* ws, const network::ErrorCode& error);
};

@interface BJIMSocketEngine()
{
@private
    IMSocketDelegate *socketDelegate;
}

@property (nonatomic, strong) BJTimer *heartBeatTimer;
@property (nonatomic, strong) NSMutableDictionary *requestQueue;

@end

@implementation BJIMSocketEngine

- (void)syncConfig
{
    __WeakSelf__ weakSelf = self;
    [NetWorkTool hermesSyncConfig:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        BaseResponse *result = [BaseResponse modelWithDictionary:response error:nil];
        if (result != nil && result.code == RESULT_CODE_SUCC)
        {
            NSError *error;
            SyncConfigModel *model = [MTLJSONAdapter modelOfClass:[SyncConfigModel class] fromJSONDictionary:result.dictionaryData error:&error];
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

- (void)start
{
    if (webSocket && webSocket->getReadyState() == network::State::OPEN)
    {
        // 已经连接上，
        return;
    }
    
    [self stop];
    webSocket = network::WebSocketInterface::createWebsocket();
    socketDelegate = new IMSocketDelegate();
    socketDelegate->engine = self;
    webSocket->init(*socketDelegate, "ws://192.168.19.102:3021");
}

- (void)stop
{
    network::WebSocketInterface::releaseWebsocket(webSocket);
    delete socketDelegate;
    socketDelegate = nullptr;
    webSocket = nullptr;
    
    [self.heartBeatTimer invalidate];
    self.heartBeatTimer = nil;
    
    self.engineActive = NO;
}

- (void)postMessage:(IMMessage *)message
{
    if (! [[IMEnvironment shareInstance] isLogin]) return;
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [dic setObject:[NSString stringWithFormat:@"%lld", message.sender] forKey:@"sender"];
    [dic setObject:[NSString stringWithFormat:@"%ld", message.senderRole] forKey:@"sender_r"];
    [dic setObject:[NSString stringWithFormat:@"%lld", message.receiver] forKey:@"receiver"];
    [dic setObject:[NSString stringWithFormat:@"%ld", message.receiverRole] forKey:@"receiver_r"];
    [dic setObject:[message.messageBody description] forKey:@"body"];
    if (message.ext)
    {
        NSString *ext = [message.ext jsonString];
        if (ext)
            [dic setObject:ext forKey:@"ext"];
    }
    [dic setObject:[NSString stringWithFormat:@"%ld", message.chat_t] forKey:@"chat_t"];
    [dic setObject:[NSString stringWithFormat:@"%ld", message.msg_t] forKey:@"msg_t"];
    [dic setObject:message.sign forKey:@"sign"];
    
    NSString *uuid = [self uuidString];
    std::string data = [self construct_req_param:dic messageType:SOCKET_API_REQUEST_MESSAGE_SEND sign:uuid];
    webSocket->send(data);
    
    [self.requestQueue setObject:message forKey:uuid];
    
}

- (void)postPullRequest:(int64_t)max_user_msg_id
        excludeUserMsgs:(NSString *)excludeUserMsgs
       groupsLastMsgIds:(NSString *)group_last_msg_ids
           currentGroup:(int64_t)groupId
{
    if (![[IMEnvironment shareInstance] isLogin]) return;
   
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[IMEnvironment shareInstance].oAuthToken forKey:@"auth_token"];
    [dic setObject:[NSString stringWithFormat:@"%lld", max_user_msg_id] forKey:@"user_last_msg_id"];
    if ([group_last_msg_ids length] > 0)
    {
        [dic setObject:group_last_msg_ids forKey:@"groups_last_msg_id"];
    }
    if (groupId > 0)
    {
        [dic setObject:[NSString stringWithFormat:@"%lld", groupId] forKey:@"current_group_id"];
    }
    
    if ([excludeUserMsgs length] > 0)
    {
        [dic setObject:excludeUserMsgs forKey:@"exclude_msg_ids"];
    }
    
    NSString *uuid = [self uuidString];
    std::string data = [self construct_req_param:dic messageType:SOCKET_API_REQUEST_MESSAGE_PULL sign:uuid];
    webSocket->send(data);
}

- (void)didReciveMessage:(NSString *)message
{
    if (! self.isEngineActive) return;
    NSDictionary *result = [message jsonValue];
    if (!result) return;
    
    NSString *messageType = [result objectForKey:@"message_type"];
    NSString *sign = [result objectForKey:@"sign"];
    NSString *response = [result objectForKey:@"response"];
    
    if ([message isEqualToString:SOCKET_API_RESPONSE_LOGIN])
    { // 登陆成功回调
//        登陆成功后再开启心跳
        self.heartBeatTimer = [BJTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(doHeartbeat) forMode:NSRunLoopCommonModes];
        // 每次登陆完成后，拉一次消息。
        [self.pollingDelegate onShouldStartPolling];
    }
    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_HEART_BEAT])
    { // 心跳回调
        self.engineActive = YES;
    }
    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_MESSAGE_PULL])
    { // 拉消息回调
        [self dealPullMessage:[response jsonValue]];
    }
    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_MESSAGE_SEND])
    { // 发消息回调
        [self dealPostMessage:[response jsonValue] sign:sign];
    }
    else if ([messageType isEqualToString:SOCKET_API_RESPONSE_MESSAGE_NEW])
    { // 有新消息
        [self.pollingDelegate onShouldStartPolling];
    }
}

- (void)dealPostMessage:(NSDictionary *)response sign:(NSString *)uuid
{
    NSError *error;
    BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
    IMMessage *msg = [self.requestQueue objectForKey:uuid];
    if (result && result.code == RESULT_CODE_SUCC)
    {
        SendMsgModel *model = [MTLJSONAdapter modelOfClass:[SendMsgModel class] fromJSONDictionary:result.data error:&error];
        
        [self.postMessageDelegate onPostMessageSucc:msg result:model];
    }
    else
    {
        [self callbackErrorCode:result.code errMsg:result.msg];
        NSError *error = [NSError bjim_errorWithReason:result.msg code:result.code];
        [self.postMessageDelegate onPostMessageFail:msg error:error];
    }
    
    [self.requestQueue removeObjectForKey:uuid];
}

- (void)dealPullMessage:(NSDictionary *)response
{
    NSError *error;
    BaseResponse *result = [BaseResponse modelWithDictionary:response error:&error];
    if (result && result.code == RESULT_CODE_SUCC)
    {
        PollingResultModel *model = [MTLJSONAdapter modelOfClass:[PollingResultModel class] fromJSONDictionary:result.data error:&error];
        [self.pollingDelegate onPollingFinish:model];
    }
    else
    {
        [self callbackErrorCode:result.code errMsg:result.msg];
    }
}

/**
 *  发送心跳
 */
-  (void)doHeartbeat
{
    std::string data = [self construct_heart_beat];
    webSocket->send(data);
}

/**
 *  发起重连
 */
- (void)reconnect
{
    [self stop];
    [self start];
}

- (void)doLogin
{
    std::string data = [self construct_login_req];
    webSocket->send(data);
    self.engineActive = YES;
}

#pragma mark construct data
- (std::string)construct_login_req
{
    NSDictionary *dic = @{
                          @"message_type":SOCKET_API_REQUEST_LOGIN,
                          @"user_number":[NSString stringWithFormat:@"%lld", [IMEnvironment shareInstance].owner.userId],
                          @"user_role":[NSString stringWithFormat:@"%ld", [IMEnvironment shareInstance].owner.userRole],
                          };
    
    
    NSString *string = [dic jsonString];
    std::string buf([string UTF8String]);
    return buf;
}

- (std::string)construct_heart_beat
{
    NSDictionary *dic = @{
                          @"message_type":SOCKET_API_REQUEST_HEART_BEAT,
                          @"user_number":[NSString stringWithFormat:@"%lld", [IMEnvironment shareInstance].owner.userId],
                          @"user_role":[NSString stringWithFormat:@"%ld", [IMEnvironment shareInstance].owner.userRole],
                          };
    
    
    NSString *string = [dic jsonString];
    std::string buf([string UTF8String]);
    return buf;
}

- (std::string)construct_req_param:(NSDictionary *)params messageType:(NSString *)messageType sign:(NSString *)uuid
{
    NSDictionary *dic = @{
                          @"message_type":messageType,
                          @"user_number":[NSString stringWithFormat:@"%lld", [IMEnvironment shareInstance].owner.userId],
                          @"user_role":[NSString stringWithFormat:@"%ld", [IMEnvironment shareInstance].owner.userRole],
                          @"param":[params socketParamsString],
                          @"sign":uuid
                          };
    
    NSString *str = [dic jsonString];
    std::string buf([str UTF8String]);
    return buf;
}

- (NSString *)uuidString
{
    double time = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%lf", time];
}

- (NSMutableDictionary *)requestQueue
{
    if (_requestQueue == nil)
    {
        _requestQueue = [[NSMutableDictionary alloc] init];
    }
    return _requestQueue;
}

#pragma mark - WebSocket Delegate
IMSocketDelegate::~IMSocketDelegate()
{
    engine = nullptr;
}

void IMSocketDelegate::onOpen(network::WebSocketInterface *ws)
{
    [engine doLogin];
}

void IMSocketDelegate::onMessage(network::WebSocketInterface *ws, const network::Data &data)
{
    NSString *string = [NSString stringWithUTF8String:data.bytes];
    [engine didReciveMessage:string];
}

void IMSocketDelegate::onClose(network::WebSocketInterface *ws)
{
//    [engine reconnect];
}

void IMSocketDelegate::onError(network::WebSocketInterface *ws, const network::ErrorCode &error)
{
    [engine reconnect];
}


@end

