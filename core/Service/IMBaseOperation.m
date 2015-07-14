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
    __weak typeof(self) __weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__weakSelf doAfterOperationOnMain];
    });
}

@end
