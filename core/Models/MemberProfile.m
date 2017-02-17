//
//  MemberProfile.m
//  Pods
//
//  Created by 辛亚鹏 on 2017/2/17.
//
//

#import "MemberProfile.h"

@implementation MemberProfile

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"userRole"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue]);
        }];
    }
    else if ([key isEqualToString:@"userId"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue]);
        }];
    }
    else if ([key isEqualToString:@"userNumber"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue]);
        }];
    }
    else if ([key isEqualToString:@"groupId"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue]);
        }];
    }
    else if ([key isEqualToString:@"isForbid"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue] == 1);
        }];
    }
    else if ([key isEqualToString:@"isAdmin"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue] == 1);
        }];
    }    
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"userId"     : @"user_id",
             @"userNumber" : @"user_number",
             @"userName"   : @"user_name",
             @"avatar"     : @"avatar",
             @"userRole"   : @"user_role",
             @"groupId"    : @"group_id",
             @"isForbid"   : @"forbid_status",
             @"isAdmin"    : @"is_admin",
             };
}


@end
