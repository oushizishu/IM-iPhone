//
//  User.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "User.h"

@implementation User

+ (NSString *)getTableName
{
    return @"USERS";
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"userId"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value longLongValue]);
        }];
    }
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
      @"userId":@"user_number",
      @"userId":@"org_id",
      @"userRole":@"user_role",
      @"name":@"user_name",
      @"avatar":@"avatar",
      };
}
@end
