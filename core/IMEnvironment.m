//
//  IMEnvironment.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "IMEnvironment.h"
#import <BJHL-Common-iOS-SDK/BJFileManagerTool.h>

@implementation IMEnvironment

+ (instancetype)shareInstance
{
    static IMEnvironment *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMEnvironment alloc] init];
        [instance initialize];
    });
    return instance;
}

- (void)initialize
{
   //init log config
}

- (void)loginWithOauthToken:(NSString *)oAuthToken
                      owner:(User *)owner
{
    _oAuthToken = oAuthToken;
    _owner = owner;
}

- (void)logout
{
    _oAuthToken = nil;
    _owner = nil;
}

- (BOOL)isLogin
{
    return _oAuthToken != nil;
}
@end
