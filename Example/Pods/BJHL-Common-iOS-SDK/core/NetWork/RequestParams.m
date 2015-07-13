//
//  RequestParams.m
//  Pods
//
//  Created by 杨磊 on 15/5/25.
//
//

#import "RequestParams.h"

@implementation FileWrapper

- (instancetype)initWithFilePath:(NSString *)filePath
{
    return [self initWithFilePath:filePath mimeType:nil];
}

- (instancetype)initWithFilePath:(NSString *)filePath mimeType:(NSString *)mimeType
{
    return [self initWithFilePath:filePath mimeType:mimeType filename:nil];
}

- (instancetype)initWithFilePath:(NSString *)filePath mimeType:(NSString *)mimeType filename:(NSString *)filename
{
    self = [super init];
    if (self)
    {
        _filePath = filePath;
        _mimeType = mimeType;
        _fileName = filename;
        
    }
    return self;
}

@end


@implementation RequestParams
@synthesize urlPostParams=_urlPostParams;
@synthesize urlGetParams=_urlGetParams;
@synthesize fileParams=_fileParams;
@synthesize requestHeaders=_requestHeaders;


#pragma mark - init
- (instancetype)init
{
    return [self initWithUrl:nil method:kHttpMethod_POST];
}

- (instancetype)initWithUrl:(NSString *)url
{
    return [self initWithUrl:url method:kHttpMethod_POST];
}

- (instancetype)initWithUrl:(NSString *)url method:(HTTPMethod)method
{
    self = [super init];
    if (self)
    {
        _url = url;
        _httpMethod = method;
        self.needGzip = YES;
        self.requestTimeOut = BJ_REQUEST_DEFAULT_TIME_OUT;
    }
    return self;
}

#pragma mark - append & remove

- (void)appendGetParamValue:(NSString *)value
                     forKey:(NSString *)key
{
    NSAssert(key != nil && value != nil, @"param key 和  value  必须都不为 nil");
    [self.urlGetParams setValue:value forKey:key];
}

- (void)appendPostParamValue:(NSString *)value
                      forKey:(NSString *)key
{
    NSAssert(key != nil && value != nil, @"param key 和  value  必须都不为 nil");
    [self.urlPostParams setValue:value forKey:key];
}

- (void)appendPostParams:(NSDictionary *)params
{
    NSArray *keys = [params allKeys];
    for (NSString *key in keys)
    {
        id value = [params valueForKey:key];
        if ([value isKindOfClass:[FileWrapper class]])
        {
            [self.fileParams setValue:value forKey:key];
        }
        else
        {
            [self appendPostParamValue:value forKey:key];
        }
    }
}

- (void)appendGetParams:(NSDictionary *)params
{
    NSArray *keys = [params allKeys];
    for (NSString *key in keys)
    {
        id value = [params valueForKey:key];
        if ([value isKindOfClass:[FileWrapper class]])
        {
            [self.fileParams setValue:value forKey:key];
        }
        else
        {
            [self appendGetParamValue:value forKey:key];
        }
    }
}

- (void)appendFile:(NSString *)filePath forKey:(NSString *)key
{
    [self appendFile:filePath mimeType:nil forKey:key];
}

- (void)appendFile:(NSString *)filePath
          mimeType:(NSString *)mimeType
           forKey:(NSString *)key
{
    [self appendFile:filePath mimeType:mimeType filename:nil forKey:key];
}

- (void)appendFile:(NSString *)filePath
          mimeType:(NSString *)mimeType
          filename:(NSString *)filename
           forKey:(NSString *)key
{
    NSAssert(key != nil, @"param key 必须不能为 nil");
    FileWrapper *wrapper = [[FileWrapper alloc] initWithFilePath:filePath
                                                        mimeType:mimeType
                                                        filename:filename
                            ];
    [self.fileParams setValue:wrapper forKey:key];
}

- (void)removeParamWithKey:(NSString *)key
{
    if (key == nil)return;
    [self.urlGetParams removeObjectForKey:key];
    [self.urlPostParams removeObjectForKey:key];
    [self.fileParams removeObjectForKey:key];
}

- (NSString *)urlWithGetParams
{
    if ([self.urlGetParams count] <= 0)
    {
        return self.url;
    }
    
    NSMutableString *__url = [[NSMutableString alloc] initWithString:self.url];
    NSRange range = [__url rangeOfString:@"?"];
    if (range.location == NSNotFound)
    {
        [__url appendString:@"?"];
    }
    
    NSArray *allKeys = [self.urlGetParams allKeys];
    for (NSString *key in allKeys) {
        [__url appendFormat:@"&%@=%@", key, [self.urlGetParams objectForKey:key]];
    }
    
    return __url;
}

#pragma mark - Setter & Getter

- (HTTPMethod)httpMethod
{
    if (_httpMethod == kHttpMethod_GET)
    {
        if ([self.urlPostParams count] > 0)
        {
            _httpMethod = kHttpMethod_POST;
        }
    }
    
    return _httpMethod;
}

- (NSUInteger)maxRetryCount
{
    _maxRetryCount = MAX(0, _maxRetryCount);
    return _maxRetryCount;
}

- (void)setNeedGzip:(BOOL)needGzip
{
    _needGzip = needGzip;
    if (_needGzip == NO)
    {
        [self removeRequestHeaderWithKey:@"Accept-Encoding"];
    }
    else
    {
        [self setRequestHeaderValue:@"gzip" forKey:@"Accept-Encoding"];
    }
}

- (void)setRequestHeaderValue:(NSString *)value forKey:(NSString *)key
{
    [self.requestHeaders setValue:value forKey:key];
}

- (void)removeRequestHeaderWithKey:(NSString *)key
{
    [self.requestHeaders removeObjectForKey:key];
}

- (NSMutableDictionary *)requestHeaders
{
    if (_requestHeaders == nil)
    {
        _requestHeaders = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _requestHeaders;
}

- (NSMutableDictionary *)urlPostParams
{
    if (_urlPostParams == nil)
    {
        _urlPostParams = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _urlPostParams;
}

- (NSMutableDictionary *)urlGetParams
{
    if (_urlGetParams == nil)
    {
        _urlGetParams = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _urlGetParams;
}

- (NSMutableDictionary *)fileParams
{
    if (_fileParams == nil)
    {
        _fileParams = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _fileParams;
}

@end
