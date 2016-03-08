//
//  NSUserDefaults+IMSDK.m
//  Pods
//
//  Created by 杨磊 on 16/3/7.
//
//

#import "NSUserDefaults+IMSDK.h"
#define KEY_IM_SDK_VERSION      @"BJHL_IM_iOS_SDK_VERSION"

@implementation NSUserDefaults (IMSDK)

+ (NSString *)getSavedIMSDKVersion
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *savedVersion = [userDefaults stringForKey:KEY_IM_SDK_VERSION];
    return savedVersion;
}

+ (void)saveIMSDKVersion:(NSString *)version
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:version forKey:KEY_IM_SDK_VERSION];
    [userDefaults synchronize];
}

@end
