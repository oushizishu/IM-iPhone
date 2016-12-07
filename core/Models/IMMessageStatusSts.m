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
    
    NSMutableString *log = [[NSMutableString alloc] init];
    [log appendString:@"\n---------------------消息发送统计-------------------------\n"];
    [log appendFormat:@"发送者 userNumber:%lld, role:%ld\n", _message.sender, _message.senderRole];
    [log appendFormat:@"接受者 userNumber:%lld, role:%ld\n", _message.receiver, _message.receiverRole];
    [log appendFormat:@"内容:\n %@\n", [_message.messageBody description]];
    [log appendString:@"~~~~~~~~~~~~~~~~~ 耗时如下: ~~~~~~~~~~~~~~~~~~~~~~~~\n"];
    [log appendFormat:@"消息发送本地消耗:%d ms\n", (int)(timeOfLocal * 1000)];
    [log appendFormat:@"消息发送远程消耗:%d ms\n", (int)(timeOfServer * 1000)];
    [log appendFormat:@"消息发送总消耗:%d ms\n", (int)(timeOfTotal * 1000)];
    [log appendFormat:@"发送结果 :%@\n", (_result?@"成功":@"失败")];
    [log appendString:@"---------------------消息发送统计  end-------------------------\n"];
    
    NSLog(log);
}

@end
