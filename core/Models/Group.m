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
    return nil;
}

/*
 {
 "id": "119981",
 "group_id": "68737",
 "user_id": "341943",
 "user_role": "2",
 "is_admin": "0",
 "ctime": "1436322533",
 "mtime": "0",
 "msg_status": "0",
 "status": "0",
 "group_name": "在线直播测试8-06月29日",
 "create_time": "1435565822",
 "can_dismiss": 0,
 "can_quit": 1
 }
 */

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
             @"msgStatus":@"msg_status"
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
             };
}

@end
