//
//  Group.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "Group.h"

@implementation Group

+ (NSString *)getTableName
{
    return @"IMGROUPS";
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
             @"memberCount":@"member_count",
             @"status":@"status",
             @"createTime":@"create_time"
             };
}
@end
