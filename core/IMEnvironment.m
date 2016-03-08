//
//  IMEnvironment.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "IMEnvironment.h"

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

- (BOOL)isCurrentChatToGroup
{
    return self.currentChatToGroupId > 0;
}

- (BOOL)isCurrentChatToUser
{
    return self.currentChatToUserId > 0 && self.currentChatToUserRole >= 0;
}

- (NSString *)getCurrentVersion
{
    return BJIM_VERSTION;
}
@end
