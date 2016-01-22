//
//  GroupDetail.m
//
//  Created by wangziliang on 15/12/4.
//
//

#import "GroupDetail.h"

@implementation GroupFile

+(NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    return nil;
}
+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"fileId":@"id",
             @"storage_id":@"storage_id",
             @"user_role":@"user_role",
             @"user_id":@"user_id",
             @"filesize":@"filesize",
             @"user_name":@"user_name",
             @"file_url":@"file_url",
             @"file_type":@"file_type",
             @"filename":@"filename",
             @"info":@"info",
             @"create_time":@"create_time",
             @"show_delete":@"show_delete",
             @"support_preview":@"support_preview",
             };
}

@end

@implementation GroupListFile

+(NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"list"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]]) {
                NSError *error;
                return [MTLJSONAdapter modelsOfClass:[GroupFile class] fromJSONArray:value error:&error];
            }
            return nil;
        }];
    }
    return nil;
}
+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"page_size":@"page_size",
             @"total":@"total",
             @"list":@"list",
             };
}

@end

@implementation GroupTeacher

+(NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    return nil;
}
+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"avatar":@"avatar",
             @"is_admin":@"is_admin",
             @"is_major":@"is_major",
             @"msg_status":@"msg_status",
             @"push_status":@"push_status",
             @"user_id":@"user_id",
             @"user_role":@"user_role",
             @"user_name":@"user_name",
             @"user_number":@"user_number",
             };
}

@end

@implementation GroupDetailMember

+(NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    return nil;
}
+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"avatar":@"avatar",
             @"is_admin":@"is_admin",
             @"is_major":@"is_major",
             @"msg_status":@"msg_status",
             @"push_status":@"push_status",
             @"user_id":@"user_id",
             @"user_role":@"user_role",
             @"user_name":@"user_name",
             @"user_number":@"user_number",
             };
}

@end

@implementation GroupNotice

+(NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    return nil;
}
+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"content":@"content",
             @"creator":@"creator",
             @"noticeId":@"id",
             @"user_id":@"user_id",
             @"user_role":@"user_role",
             @"create_date":@"create_date",
             };
}

@end

@implementation GroupSource

+(NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"major_teacher_list"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]]) {
                NSError *error;
                return [MTLJSONAdapter modelsOfClass:[GroupTeacher class] fromJSONArray:value error:&error];
            }
            return nil;
        }];
    }
    return nil;
}
+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"course":@"course",
             @"course_arrange":@"course_arrange",
             @"order_url":@"order_url",
             @"major_teacher_list":@"major_teacher_list",
             };
}

@end

@implementation GroupDetail

+(NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"group_source"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                NSError *error;
                return [MTLJSONAdapter modelOfClass:[GroupSource class] fromJSONDictionary:value error:&error];
            }
            return nil;
        }];
    }else if ([key isEqualToString:@"member_list"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]]) {
                NSError *error;
                return [MTLJSONAdapter modelsOfClass:[GroupDetailMember class] fromJSONArray:value error:&error];
            }
            return nil;
        }];
    }else if ([key isEqualToString:@"notice"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                NSError *error;
                return [MTLJSONAdapter modelOfClass:[GroupNotice class] fromJSONDictionary:value error:&error];
            }
            return nil;
        }];
    }
    return nil;
}
+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"group_id":@"group_id",
             @"group_name":@"group_name",
             @"avatar":@"avatar",
             @"create_time":@"create_time",
             @"detailDescription":@"description",
             @"maxusers":@"maxusers",
             @"membercount":@"membercount",
             @"origin_avatar":@"origin_avatar",
             @"status":@"status",
             @"user_id":@"user_id",
             @"user_number":@"user_number",
             @"user_role":@"user_role",
             @"group_source":@"group_source",
             @"member_list":@"member_list",
             @"notice":@"notice",
             @"msg_status":@"msg_status",
             @"is_admin":@"is_admin",
             };
}

@end
