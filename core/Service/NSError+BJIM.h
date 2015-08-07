//
//  NSError+GroupManager.h
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import <Foundation/Foundation.h>

@interface NSError (BJIM)
+ (NSError *)bjim_errorWithReason:(NSString *)reason;
+ (NSError *)bjim_errorWithReason:(NSString *)reason code:(NSInteger)code;
+ (NSError *)bjim_loginError;
- (NSString *)bjim_Reason;
@end
