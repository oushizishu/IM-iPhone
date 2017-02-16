//
//  SearchMember.m
//  Pods
//
//  Created by 辛亚鹏 on 2017/2/15.
//
//

#import "SearchMemberList.h"

//static int ddLogLevel = DDLogLevelVerbose;

@implementation SearchMember

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"userRole"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
                return @([value integerValue]);
        }];
    }
    else if ([key isEqualToString:@"msgStatus"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue]);
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
             @"msgStatus"  : @"msg_status",
             @"pushStatus" : @"push_status",
             @"isMajor"    : @"is_major",
             @"isAdmin"    : @"is_admin",
             };
}

@end

/*
@implementation SearchMemberList

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"list"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]]) {
                return [MTLJSONAdapter modelsOfClass:[SearchMember class] fromJSONArray:value error:error];
            }
            else {
                DDLogError(@"jsonModel trans fail value的类型不对");
            }
            return nil;
        }];
    }
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"memberList" : @"list",
             };
}

@end
*/
