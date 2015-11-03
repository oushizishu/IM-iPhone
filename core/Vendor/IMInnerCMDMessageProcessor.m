//
//  IMInnerCMDMessageProcessor.m
//  Pods
//
//  Created by 杨磊 on 15/10/22.
//
//

#import "IMInnerCMDMessageProcessor.h"
#import "BJIMConstants.h"
#import "HandleCmdMessageOperation.h"

@implementation IMInnerCMDMessageProcessor

+ (BOOL)processMessage:(IMMessage *)message withService:(BJIMService *)imService
{
    if (message.msg_t != eMessageType_CMD)
        return NO;
    
    IMCmdMessageBody *messageBody = (IMCmdMessageBody *)message.messageBody;
    if (messageBody.type != 0) return NO; // 非内部处理
    
    HandleCmdMessageOperation *operation = [[HandleCmdMessageOperation alloc] init];
    operation.imService = imService;
    operation.message = message;
    
    [imService appendOperationAfterContacts:operation];
    return YES;
}

@end
