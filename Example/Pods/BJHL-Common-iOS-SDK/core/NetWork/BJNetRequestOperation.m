//
//  BJNetRequestOperation.m
//  Pods
//
//  Created by 杨磊 on 15/6/1.
//
//

#import "BJNetRequestOperation.h"

@implementation BJNetRequestOperation

- (instancetype)initWithHttpOperation:(AFHTTPRequestOperation *)operation
{
    self = [super init];
    if (self)
    {
        _httpOperation = operation;
    }
    return self;
}

- (void)cancel
{
    [_httpOperation cancel];
}

- (BOOL)isCancelled
{
    return [_httpOperation isCancelled];
}

@end
