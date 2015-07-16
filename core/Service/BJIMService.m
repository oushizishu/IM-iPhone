//
//  BJIMService.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "BJIMService.h"
#import "SendMsgOperation.h"
#import <BJHL-Common-iOS-SDK/BJCommonDefines.h>

@interface BJIMService()<IMEnginePostMessageDelegate>

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL bIsServiceActive;

@end

@implementation BJIMService
@synthesize imEngine=_imEngine;
@synthesize imStorage=_imStorage;

- (void)startServiceWithOwner:(User *)owner
{
    __WeakSelf__ weakSelf = self;
    [self.imEngine syncConfig];
    self.bIsServiceActive = YES;
}

- (void)stopService
{
    [self.operationQueue cancelAllOperations];
    self.bIsServiceActive = NO;
}

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message
{
    message.status = eMessageStatus_Sending;
    SendMsgOperation *operation = [[SendMsgOperation alloc] init];
    operation.imService = self;
    [self.operationQueue addOperation:operation];
}

- (void)retryMessage:(IMMessage *)message
{

}

#pragma mark - Post Message Delegate
- (void)onPostMessageSucc:(IMMessage *)message
{
    message.status = eMessageStatus_Send_Succ;
}

- (void)onPostMessageFail:(IMMessage *)message error:(NSError *)error
{
    message.status = eMessageStatus_Send_Fail;
}

#pragma mark - Setter & Getter
- (BJIMEngine *)imEngine
{
    if (_imEngine == nil)
    {
        _imEngine = [[BJIMEngine alloc] init];
    }
    return _imEngine;
}

- (BJIMStorage *)imStorage
{
    if (_imStorage == nil)
    {
        _imStorage = [[BJIMStorage alloc] init];
    }
    return _imStorage;
}

- (NSOperationQueue *)operationQueue
{
    if (_operationQueue == nil)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:3];
    }
    return _operationQueue;
}

- (BOOL)bIsServiceActive
{
    return _bIsServiceActive;
}

#pragma mark - application call back
- (void)applicationEnterForeground
{
    [self.imEngine start];
}

- (void)applicationEnterBackground
{
    [self.imEngine stop];
}
@end
