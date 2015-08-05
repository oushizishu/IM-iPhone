//
//  SyncConfigModel.m
//  Pods
//
//  Created by 杨磊 on 15/7/16.
//
//

#import "SyncConfigModel.h"

@implementation SimpleUserModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"number":@"number",
             @"role":@"role"
             };
}

@end

@implementation SyncConfigModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"polling_delta":@"polling_delta",
             @"close_polling":@"close_polling",
             @"administrators":@"sys_user.administrators",
             @"customWaiter":@"sys_user.kefu",
             @"systemSecretary":@"sys_user.sys",
             };
}
@end
