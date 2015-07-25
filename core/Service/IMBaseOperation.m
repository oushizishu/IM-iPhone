//
//  IMBaseOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMBaseOperation.h"

@implementation IMBaseOperation

- (void)doOperationOnBackground
{
}

- (void)doAfterOperationOnMain
{
}

- (void)main
{
    [self doOperationOnBackground];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self doAfterOperationOnMain];
    });
}

@end
