//
//  BJCommonProxy.m
//  Pods
//
//  Created by 杨磊 on 15/5/25.
//
//

#import "BJCommonProxy.h"

@implementation BJCommonProxy
@synthesize networkUtil=_networkUtil;
@synthesize fileCacheManager=_fileCacheManager;

+ (instancetype)sharedInstance
{
    static BJCommonProxy *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[super alloc] init];
    });
    return _sharedInstance;
}

- (BJNetworkUtil *)networkUtil
{
    if (_networkUtil == nil)
    {
        _networkUtil = [[BJNetworkUtil alloc] init];
    }
    return _networkUtil;
}

- (BJCacheManagerTool *)fileCacheManager
{
    if (_fileCacheManager == nil)
    {
        _fileCacheManager = [[BJCacheManagerTool alloc] init];
    }
    return _fileCacheManager;
}

@end
