//
//  NSUserDefault.m
//  Pods
//
//  Created by 杨磊 on 15/9/18.
//
//

#import "NSUserDefaults+Device.h"

@implementation NSUserDefaults(Device)

+ (NSString *)deviceString
{

//    [[NSUUID UUID] UUIDString];
    NSString *string = [[NSUserDefaults standardUserDefaults] objectForKey:@"hermes-uuid"];
    if ([string length] == 0)
    {
        string = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"hermes-uuid"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return string;
}

@end
