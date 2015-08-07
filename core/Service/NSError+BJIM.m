//
//  NSError+GroupManager.m
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import "NSError+BJIM.h"
#import "BJIMConstants.h"

@implementation NSError (BJIM)

+ (NSError *)bjim_errorWithReason:(NSString *)reason code:(NSInteger)code;
{
    if (reason == nil) {
        reason = @"";
    }
    return [[NSError alloc] initWithDomain:@"API_BJIM_Error" code:code userInfo:[NSDictionary dictionaryWithObject:reason forKey:NSLocalizedFailureReasonErrorKey]];
}

+ (NSError *)bjim_loginError;
{
    return [NSError bjim_errorWithReason:@"未登录" code:eError_noLogin];
}

+ (NSError *)bjim_errorWithReason:(NSString *)reason;
{
    return [NSError bjim_errorWithReason:reason code:eError_msgError];
}

- (NSString *)bjim_Reason
{
    return self.localizedFailureReason;

}

@end
