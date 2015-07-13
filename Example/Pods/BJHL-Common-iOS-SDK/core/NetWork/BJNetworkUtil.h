//
//  BJNetworkUtil.h
//  Pods
//
//  Created by 杨磊 on 15/5/25.
//
//

#import <Foundation/Foundation.h>
#import "RequestParams.h"
#import "BJNetRequestOperation.h"

typedef void(^onSuccess)(id response, NSDictionary *responseHeaders, RequestParams *params);
typedef void(^onFailure)(NSError *error, RequestParams *params);
typedef void(^onRetryRequest)(NSError *error, RequestParams *params, BJNetRequestOperation *newOperation);
typedef void(^onProgress)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpected);

@interface BJNetworkUtil : NSObject

- (BJNetRequestOperation *)doNetworkRequest:(RequestParams *)requestParams
                                    success:(onSuccess)success
                                    failure:(onFailure)failure;

- (BJNetRequestOperation *)doNetworkRequest:(RequestParams *)requestParams
                                    success:(onSuccess)success
                                      retry:(onRetryRequest)retry
                                    failure:(onFailure)failure;

/**
 *  处理网络请求
 *
 *  @param requestParams requestParams description
 *  @param success       success description
 *  @param failure       <#failure description#>
 *  @param progress      <#progress description#>
 */
- (BJNetRequestOperation *)doNetworkRequest:(RequestParams *)requestParams
                 success:(onSuccess)success
                 failure:(onFailure)failure
                   retry:(onRetryRequest)retry
                progress:(onProgress)progress;

- (BJNetRequestOperation *)doDownloadResource:(RequestParams *)requestParams
                                 fileDownPath:(NSString *)filePath
                                      success:(onSuccess)success
                                      failure:(onFailure)failure
                                     progress:(onProgress)progress;

/**
 *  下载文件
 *
 *  @param requestParams <#requestParams description#>
 *  @param filePath      下载文件的存储路径
 *  @param success       <#success description#>
 *  @param failure       <#failure description#>
 *  @param progress      <#progress description#>
 */
- (BJNetRequestOperation *)doDownloadResource:(RequestParams *)requestParams
              fileDownPath:(NSString *)filePath
                   success:(onSuccess)success
                     retry:(onRetryRequest)retry
                   failure:(onFailure)failure
                  progress:(onProgress)progress;

@end
