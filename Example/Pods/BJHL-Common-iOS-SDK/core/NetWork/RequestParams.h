//
//  RequestParams.h
//  Pods
//
//  Created by 杨磊 on 15/5/25.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HTTPMethod) {
    kHttpMethod_GET = 0,
    kHttpMethod_POST = 1
};

@interface FileWrapper : NSObject

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *fileName;

- (instancetype)initWithFilePath:(NSString *)filePath;
- (instancetype)initWithFilePath:(NSString *)filePath mimeType:(NSString *)mimeType;
- (instancetype)initWithFilePath:(NSString *)filePath mimeType:(NSString *)mimeType filename:(NSString *)filename;

@end

#define BJ_REQUEST_DEFAULT_TIME_OUT 60

/**
 *  @brief 封装网络请求参数
 *  默认使用 HttpPost 方式请求， 开启 Gzip。
 */
@interface RequestParams : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) HTTPMethod httpMethod;
@property (nonatomic, assign, getter=isGZIP) BOOL needGzip;
@property (nonatomic, assign) NSUInteger requestTimeOut;

/** 请求最大重试次数*/
@property (nonatomic, assign) NSUInteger maxRetryCount;

@property (nonatomic, strong, readonly) NSMutableDictionary *urlPostParams;
@property (nonatomic, strong, readonly) NSMutableDictionary *urlGetParams;
@property (nonatomic, strong, readonly) NSMutableDictionary *fileParams;
@property (nonatomic, strong, readonly) NSMutableDictionary *requestHeaders;

- (instancetype)initWithUrl:(NSString *)url;
- (instancetype)initWithUrl:(NSString *)url method:(HTTPMethod)method;

/**
    post 上传的 参数
 */
- (void)appendPostParamValue:(NSString *)value forKey:(NSString *)key;

/**
    附加在 url 地址后的参数列
 */
- (void)appendGetParamValue:(NSString *)value forKey:(NSString *)key;

/**
    批量设置参数
 */
- (void)appendPostParams:(NSDictionary *)params;
- (void)appendGetParams:(NSDictionary *)params;

- (void)appendFile:(NSString *)filePath
           forKey:(NSString *)key;

- (void)appendFile:(NSString *)filePath
          mimeType:(NSString *)mimeType
           forKey:(NSString *)key;

/**
 *  @brief 添加需要上传的文件
 *
 *  @param filePath 文件路径
 *  @param mimeType 文件类型
 *  @param filename 文件名称
 *  @param key      上传 key
 */
- (void)appendFile:(NSString *)filePath
          mimeType:(NSString *)mimeType
          filename:(NSString *)filename
           forKey:(NSString *)key;

- (void)removeParamWithKey:(NSString *)key;

/**
 *  设置请求头信息
 *
 *  @param key   <#key description#>
 *  @param value <#value description#>
 */
- (void)setRequestHeaderValue:(NSString *)value forKey:(NSString *)key;
- (void)removeRequestHeaderWithKey:(NSString *)key;

- (NSString *)urlWithGetParams;
@end
