//
//  Group.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "Group.h"
#import <LKDBHelper/LKDB+Mapping.h>

@implementation Group

+ (NSString *)getTableName
{
    return @"IMGROUPS";
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"groupId"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value longLongValue]);
        }];
    }
    else if ([key isEqualToString:@"joinTime"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
            return date;
        }];
    }
    else if ([key isEqualToString:@"isAdmin"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value integerValue] == 0);
        }];
    }
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"groupId":@"group_id",
             @"groupName":@"group_name",
             @"avatar":@"avatar",
             @"descript":@"description",
             @"isPublic":@"is_public",
             @"maxusers":@"maxusers",
             @"approval":@"approval",
             @"ownerId":@"owner_id",
             @"ownerRole":@"owner_role",
             @"memberCount":@"membercount",
             @"status":@"status",
             @"createTime":@"create_time",
             @"nameHeader":@"name_header",
             @"remarkName":@"remark_name",
             @"remarkHeader":@"remark_header",
             @"canLeave":@"can_quit",
             @"canDisband":@"can_dismiss",
             @"msgStatus":@"msg_status",
             @"pushStatus":@"push_status",
             @"isAdmin":@"is_admin",
             @"joinTime":@"join_time"
             };
}

+ (NSDictionary *)getTableMapping
{
    return @{
             @"groupId":@"groupId",
             @"groupName":@"groupName",
             @"avatar":@"avatar",
             @"descript":@"descript",
             @"isPublic":@"isPublic",
             @"maxusers":@"maxusers",
             @"approval":@"approval",
             @"ownerId":@"ownerId",
             @"ownerRole":@"ownerRole",
             @"memberCount":@"memberCount",
             @"status":@"status",
             @"createTime":@"createTime",
             @"nameHeader":@"nameHeader",
             @"isAdmin":@"isAdmin"
             };
}

@end
