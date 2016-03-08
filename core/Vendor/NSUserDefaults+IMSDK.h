//
//  NSUserDefaults+IMSDK.h
//  Pods
//
//  Created by 杨磊 on 16/3/7.
//
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (IMSDK)

/**
 *  获取已保存的 IM SDK verison
 *
 *  @return <#return value description#>
 */
+ (NSString *)getSavedIMSDKVersion;

/**
 *  保存当前 IM SDK version
 *
 *  @param version <#version description#>
 */
+ (void)saveIMSDKVersion:(NSString *)version;

@end
