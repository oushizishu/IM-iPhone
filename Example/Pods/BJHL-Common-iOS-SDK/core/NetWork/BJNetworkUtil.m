//
//  BJNetworkUtil.m
//  Pods
//
//  Created by 杨磊 on 15/5/25.
//
//

#import "BJNetworkUtil.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <MobClick.h>

@implementation BJNetworkUtil

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    }
    return self;
}

- (BJNetRequestOperation *)doNetworkRequest:(RequestParams *)requestParams
                                    success:(onSuccess)success
                                    failure:(onFailure)failure
{
    return [self doNetworkRequest:requestParams success:success retry:nil failure:failure];
}

- (BJNetRequestOperation *)doNetworkRequest:(RequestParams *)requestParams
                                    success:(onSuccess)success
                                      retry:(onRetryRequest)retry
                                    failure:(onFailure)failure
{
    return [self doNetworkRequest:requestParams success:success failure:failure retry:retry progress:nil];
}

- (BJNetRequestOperation *)doNetworkRequest:(RequestParams *)requestParams
                                    success:(onSuccess)success
                                    failure:(onFailure)failure
                                      retry:(onRetryRequest)retry
                                   progress:(onProgress)progress
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //https
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    //response
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
    responseSerializer.removesKeysWithNullValues = YES;
    
    NSMutableSet *contentTypes = [NSMutableSet setWithSet:responseSerializer.acceptableContentTypes];
    [contentTypes addObject:@"text/plain"];
    responseSerializer.acceptableContentTypes = contentTypes;
    
    manager.responseSerializer = responseSerializer;
    
    //request
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setTimeoutInterval:requestParams.requestTimeOut];
    
    NSMutableURLRequest *request = nil;
   
    if (requestParams.httpMethod == kHttpMethod_GET)
    {
        //Get
        NSError *error = nil;
        request = [manager.requestSerializer requestWithMethod:@"GET" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams error:&error];
    }
    else if (requestParams.httpMethod == kHttpMethod_POST)
    {
        //Post
        NSError *error = nil;
        request = [manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            NSArray *allKeys = requestParams.fileParams.allKeys;
            for (NSString *key in allKeys) {
                FileWrapper *wrapper = [requestParams.fileParams objectForKey:key];
                NSURL *fileUrl = [NSURL fileURLWithPath:wrapper.filePath];
                NSError *error = nil;
                [formData appendPartWithFileURL:fileUrl name:key fileName:wrapper.fileName mimeType:wrapper.mimeType error:&error];
            }
        } error:&error];
    }
    
    NSDate *__date = [NSDate date];
    //request headers
    request.allHTTPHeaderFields = requestParams.requestHeaders;
    
    __weak typeof(self) weakSelf = self;
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success && ![operation isCancelled])
        {
            success(responseObject, operation.response.allHeaderFields, requestParams);
        }
        
        AFNetworkReachabilityStatus networkStatu =  [manager reachabilityManager].networkReachabilityStatus;
        NSString *netStr = @"NONE";
        if (networkStatu == AFNetworkReachabilityStatusReachableViaWiFi)
        {
            netStr = @"WIFI";
        }
        else if (networkStatu == AFNetworkReachabilityStatusReachableViaWWAN)
        {
            netStr = @"3G";
        }
        //网络状态统计
        NSDictionary *pms = @{@"net":netStr};
        double _delta = [[NSDate date] timeIntervalSince1970] - [__date timeIntervalSince1970];
        [MobClick event:@"request_success" attributes:pms durations:(int)_delta * 1000];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
        AFNetworkReachabilityStatus networkStatu =  [manager reachabilityManager].networkReachabilityStatus;
        NSString *netStr = @"NONE";
        if (networkStatu == AFNetworkReachabilityStatusReachableViaWiFi)
        {
            netStr = @"WIFI";
        }
        else if (networkStatu == AFNetworkReachabilityStatusReachableViaWWAN)
        {
            netStr = @"3G";
        }
        //网络状态统计
        NSDictionary *pms = @{@"net":netStr, @"err": [NSString stringWithFormat:@"%@,%@", operation.request.URL.path, error.localizedDescription]};
        double _delta = [[NSDate date] timeIntervalSince1970] - [__date timeIntervalSince1970];
        [MobClick event:@"request_fail" attributes:pms durations:(int)_delta * 1000];
        
        
        if (requestParams.maxRetryCount > 0)
        {
            requestParams.maxRetryCount --;
            
           BJNetRequestOperation *op = [weakSelf doNetworkRequest:requestParams success:success failure:failure retry:retry progress:progress];
            if (retry)
            {
                retry(error, requestParams, op);
            }
            return ;
        }
       if (failure && ![operation isCancelled])
       {
           failure(error, requestParams);
       }
    }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (progress)
        {
            progress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }
    }];
    
    [operation start];
    return [[BJNetRequestOperation alloc] initWithHttpOperation:operation];
}


- (BJNetRequestOperation *)doDownloadResource:(RequestParams *)requestParams
                                 fileDownPath:(NSString *)filePath
                                      success:(onSuccess)success
                                      failure:(onFailure)failure
                                     progress:(onProgress)progress
{
    return [self doDownloadResource:requestParams fileDownPath:filePath success:success retry:nil failure:failure progress:progress];
}

- (BJNetRequestOperation *)doDownloadResource:(RequestParams *)requestParams
                                 fileDownPath:(NSString *)filePath
                                      success:(onSuccess)success
                                        retry:(onRetryRequest)retry
                                      failure:(onFailure)failure
                                     progress:(onProgress)progress
{
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    // timeout
    [requestSerializer setTimeoutInterval:requestParams.requestTimeOut];
    
    NSError *error = nil;
    NSURLRequest *request = [requestSerializer requestWithMethod:@"GET" URLString:[requestParams urlWithGetParams] parameters:requestParams.urlPostParams error:&error];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.securityPolicy.allowInvalidCertificates = YES;
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (progress)
        {
            progress(bytesRead, totalBytesRead, totalBytesExpectedToRead);
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success && ![operation isCancelled])
        {
            success(responseObject, operation.response.allHeaderFields, requestParams);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (requestParams.maxRetryCount > 0)
        {
            requestParams.maxRetryCount -- ;
            BJNetRequestOperation *op = [weakSelf doDownloadResource:requestParams fileDownPath:filePath success:success retry:retry failure:failure progress:progress];
            if (retry)
            {
                retry(error, requestParams, op);
            }
            return ;
        }
       if (failure && ![operation isCancelled])
       {
           failure(error, requestParams);
       }
    }];
    
    [operation start];
    return [[BJNetRequestOperation alloc] initWithHttpOperation:operation];
}

@end
