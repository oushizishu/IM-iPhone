//
//  User.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "User.h"
#import <NSObject+LKDBHelper.h>

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
    } else if ([key isEqualToString:@"focusTime"] || [key isEqualToString:@"fansTime"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            NSTimeInterval timestamp = [value doubleValue];
            return [NSDate dateWithTimeIntervalSince1970:timestamp];
            
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
      @"nameHeader":@"name_header",
      @"remarkName":@"remark_name",
      @"remarkHeader":@"remark_header",
      @"blackStatus":@"black_status",
      @"originType":@"origin_type",
      @"focusType":@"focus_type",
      @"tinyFocus":@"tiny_focus",
      @"focusTime":@"focus_time",
      @"fansTime":@"fans_time",
      @"blackStatus":@"black_status"
      };
}

+ (NSDictionary *)getTableMapping
{
    return @{
             @"userId":@"userId",
             @"userId":@"userId",
             @"userRole":@"userRole",
             @"name":@"name",
             @"avatar":@"avatar",
             @"nameHeader":@"nameHeader"
             };
}

@end
