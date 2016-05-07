//
//  SyncConfigModel.m
//  Pods
//
//  Created by 杨磊 on 15/7/16.
//
//

#import "SyncConfigModel.h"
#import "IMJSONAdapter.h"

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

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"administrators"] || [key isEqualToString:@"customWaiter"] || [key isEqualToString:@"systemSecretary"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                SimpleUserModel *user = [IMJSONAdapter modelOfClass:[SimpleUserModel class] fromJSONDictionary:value error:error];
                return user;
            }
            else if (value)
            {
                NSAssert(0, @"value类型不对");
            }
            return nil;
        }];
    }
    return nil;
}

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
