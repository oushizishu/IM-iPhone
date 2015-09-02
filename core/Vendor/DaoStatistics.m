//
//  DaoStatistics.m
//  Pods
//
//  Created by 杨磊 on 15/9/1.
//
//

#import "DaoStatistics.h"
#import "IMEnvironment.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

static int ddLogLevel = DDLogLevelVerbose;

#define DEBUG_MODE_CODE_BEGIN if ([IMEnvironment shareInstance].debugMode == eIMServer_Environment_test) {
#define DEBUG_MODE_CODE_END }

@interface DaoStatistics()
{
    NSInteger sqlCount;
    NSInteger cacheCount;
}
@end

@implementation DaoStatistics

+ (instancetype)sharedInstance
{
    static DaoStatistics *instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instance = [[DaoStatistics alloc] init];
    });
    return instance;
}

- (void)logDBOperationSQL:(NSString *)sql class:(__unsafe_unretained Class)clazz
{
    DEBUG_MODE_CODE_BEGIN
    
    sqlCount ++ ;
    if (sql)
        DDLogInfo(@"DaoStatistics target:[%@] SQL:[%@]", clazz, sql);
    
    if (sqlCount % 30 == 0)
        [self statistics];
    
    DEBUG_MODE_CODE_END
}

- (void)logDBCacheSQL:(NSString *)sql class:(__unsafe_unretained Class)clazz
{
    DEBUG_MODE_CODE_BEGIN
    
    cacheCount ++ ;
    DDLogInfo(@"DaoStatistics target:[%@] SQL Cache :[%@]", clazz, sql);
    if (cacheCount % 30 == 0)
        [self statistics];
    DEBUG_MODE_CODE_END
}

- (void)statistics
{
    DEBUG_MODE_CODE_BEGIN
    
    DDLogInfo(@"********DaoStatistics [sqlCount:%ld] [cacheCount:%ld]*********************", (long)sqlCount, (long)cacheCount);
    
    DEBUG_MODE_CODE_END
}

@end
