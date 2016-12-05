//
//  IMMessageStatusSts.m
//  Pods
//
//  Created by 杨磊 on 2016/12/5.
//
//

#import "IMMessageStatusSts.h"
#import "IMMessage.h"

@interface IMMessageStatusSts()
@property (nonatomic, assign, readonly) NSTimeInterval msgStartSendTime;
@property (nonatomic, assign, readonly) NSTimeInterval msgStartSendServerTime;
@property (nonatomic, assign, readonly) NSTimeInterval msgFinishSendTime;
@property (nonatomic, assign, readonly) BOOL result;
@end

@implementation IMMessageStatusSts
@synthesize message=_message;

- (void)markStartSend
{
    _msgStartSendTime = [[NSDate date] timeIntervalSince1970];
}

- (void)markStartSendServer
{
    _msgStartSendServerTime = [[NSDate date] timeIntervalSince1970];
}

- (void)markFinishSendWithResult:(BOOL)succOrFail
{
    _msgFinishSendTime = [[NSDate date] timeIntervalSince1970];
    _result = succOrFail;
}


- (void)printMessageStatictis
{
    NSTimeInterval timeOfLocal = self.msgStartSendServerTime - self.msgStartSendTime;
    NSTimeInterval timeOfServer = self.msgFinishSendTime - self.msgStartSendServerTime;
    NSTimeInterval timeOfTotal = self.msgFinishSendTime - self.msgStartSendTime;
    
    NSString *log1 = [NSString stringWithFormat:@"消息发送本地消耗:%d s", (int)(timeOfLocal)];
    NSString *log2 = [NSString stringWithFormat:@"消息发送远程消耗:%d s", (int)(timeOfServer)];
    NSString *log3 = [NSString stringWithFormat:@"消息发送总消耗:%d s", (int)(timeOfTotal)];
    NSLog(@"---------------------消息发送统计-------------------------");
    NSLog(@"发送者 userNumber:%lld, role:%ld", _message.sender, _message.senderRole);
    NSLog(@"接受者 userNumber:%lld, role:%ld", _message.receiver, _message.receiverRole);
    NSLog(@"内容 %@", [_message.messageBody description]);
    NSLog(@"~~~~~~~~~~~~~~~~~ 耗时 ~~~~~~~~~~~~~~~~~~~~~~~~");
    NSLog(log1);
    NSLog(log2);
    NSLog(log3);
    NSLog(@"发送结果 :%@", (_result?@"成功":@"失败"));
    NSLog(@"---------------------消息发送统计  end-------------------------");
}

@end
