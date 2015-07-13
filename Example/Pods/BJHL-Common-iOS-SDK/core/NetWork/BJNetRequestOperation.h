//
//  BJNetRequestOperation.h
//  Pods
//
//  Created by 杨磊 on 15/6/1.
//
//

#import <Foundation/Foundation.h>
#import <AFHTTPRequestOperation.h>

@interface BJNetRequestOperation : NSObject

- (instancetype)initWithHttpOperation:(AFHTTPRequestOperation *)operation;

- (void)cancel;

- (BOOL)isCancelled;
@property (nonatomic, strong,readonly) AFHTTPRequestOperation *httpOperation;
@end
