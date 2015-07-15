//
//  SendMsgOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "SendMsgOperation.h"

@implementation SendMsgOperation

- (void)doOperationOnBackground
{
}

- (void)doAfterOperationOnMain
{
    [self.imService.imEngine postMessage:self.message];
}

@end
