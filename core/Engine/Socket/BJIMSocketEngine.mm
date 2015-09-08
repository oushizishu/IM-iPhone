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

//static int ddLogLevel = DDLogLevelVerbose;

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

- (void)doLogin;

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
//            DDLogWarn(@"Sync Config Fail [url:%@][params:%@]", params.url, params.urlPostParams);
            [self callbackErrorCode:result.code errMsg:result.msg];
        }
    } failure:^(NSError *error, RequestParams *params) {
//        DDLogError(@"Sync Config Fail [%@]", error.userInfo);
        
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
}

- (void)postMessage:(IMMessage *)message
{
}

- (void)postPullRequest:(int64_t)max_user_msg_id
        excludeUserMsgs:(NSString *)excludeUserMsgs
       groupsLastMsgIds:(NSString *)group_last_msg_ids
           currentGroup:(int64_t)groupId
{
}

- (void)doLogin
{

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
}

void IMSocketDelegate::onClose(network::WebSocketInterface *ws)
{
}

void IMSocketDelegate::onError(network::WebSocketInterface *ws, const network::ErrorCode &error)
{
}


@end
