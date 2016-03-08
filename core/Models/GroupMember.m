//
//  GroupMember.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "GroupMember.h"
#import <LKDBHelper.h>

@implementation GroupMember


+ (NSString *)getTableName
{
    return @"GROUPMEMBER";
}

+ (NSDictionary *)getTableMapping
{
    return @{
             @"userId":@"userId",
             @"userRole":@"userRole",
             @"groupId":@"groupId",
             @"isAdmin":@"isAdmin",
             @"createTime":@"createTime",
             @"msgStatus":@"msgStatus",
             @"canLeave":@"canLeave",
             @"canDisband":@"canDisband",
             @"pushStatus":@"pushStatus",
             @"remarkName":@"remarkName",
             @"remarkHeader":@"remarkHeader",
             @"joinTime":@"joinTime"
             };
}

@end
