//
//  Contacts.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "Contacts.h"

@implementation Contacts

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"userId":@"user_id",
             @"contactId":@"contact_id",
             @"contactRole":@"contact_role",
             @"createTime":@"create_time"
             };
}

@end
