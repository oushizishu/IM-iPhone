//
//  BJCommonProxy.h
//  Pods
//
//  Created by 杨磊 on 15/5/25.
//
//

#import <Foundation/Foundation.h>
#import "BJNetworkUtil.h"
#import "BJCacheManagerTool.h"
#import "UIImageView+Aliyun.h"
#import "BJCommonDefines.h"

#ifndef __BJCOMMONPROXY__
#define __BJCOMMONPROXY__

#define BJCommonProxyInstance [BJCommonProxy sharedInstance]

#endif

@interface BJCommonProxy : NSObject

/**
 *  网络模块
 */
@property (nonatomic, strong, readonly) BJNetworkUtil *networkUtil;
/**
 *  文件缓存模块
 */
@property (nonatomic, strong, readonly) BJCacheManagerTool *fileCacheManager;

+ (instancetype)sharedInstance;

@end
