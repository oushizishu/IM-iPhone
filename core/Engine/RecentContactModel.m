//
//  RecentContactModel.m
//  Pods
//
//  Created by 杨磊 on 15/8/4.
//
//

#import "RecentContactModel.h"

@implementation RecentContactModel

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
             @"updateTime":@"update_time"
             };
}

@end
