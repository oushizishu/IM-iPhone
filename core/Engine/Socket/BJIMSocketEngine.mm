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

static DDLogLevel ddLogLevel = DDLogLevelVerbose;


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
    
//登陆成功后再开启心跳
//    self.heartBeatTimer = [BJTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(doHeartbeat) forMode:NSRunLoopCommonModes];
//    
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
    
    std::string data = [self construct_req_param:dic];
    webSocket->send(data);
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
    
    std::string data = [self construct_req_param:dic];
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
    
    if ([message isEqualToString:@"session_record"])
    { // 登陆成功回调
    
    }
    else if ([message isEqualToString:@"heart_beat"])
    { // 心跳回调
    
    }
    else if ([message isEqualToString:@"message_pull_req"])
    { // 拉消息回调
    }
    else if ([message isEqualToString:@"message_send_req"])
    { // 发消息回调
    
    }
}

/**
 *  发送心跳
 */
-  (void)doHeartbeat
{
    std::string data = [self construct_no_params_req];
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
    std::string data = [self construct_no_params_req];
    webSocket->send(data);
    self.engineActive = YES;
}

#pragma mark construct data
- (std::string)construct_no_params_req
{
    NSDictionary *dic = @{
                          @"message_type":@"session_record",
                          @"PHPSESSION":@"",
                          @"user_number":[NSString stringWithFormat:@"%lld", [IMEnvironment shareInstance].owner.userId],
                          @"user_role":[NSString stringWithFormat:@"%ld", [IMEnvironment shareInstance].owner.userRole],
                          };
    
    
    NSString *string = [dic jsonString];
    std::string buf([string UTF8String]);
    return buf;
}

- (std::string)construct_req_param:(NSDictionary *)params
{
    NSString *uuid = [self uuidString];
    NSDictionary *dic = @{
                          @"message_type":@"message_send_req",
                          @"PHPSESSID":@"",
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
    [engine reconnect];
}

void IMSocketDelegate::onError(network::WebSocketInterface *ws, const network::ErrorCode &error)
{
    [engine reconnect];
}


@end

