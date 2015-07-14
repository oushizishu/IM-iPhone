//
//  IMEnvironment.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface IMEnvironment : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, copy, readonly) NSString *oAuthToken;
@property (nonatomic, strong, readonly) User *owner;

- (void)loginWithOauthToken:(NSString *)oAuthToken
                      owner:(User *)owner;

- (void)logout;

- (BOOL)isLogin;

@end
