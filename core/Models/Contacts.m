//
//  Contacts.m
//  Pods
//
//  Created by 杨磊 on 16/3/7.
//
//

#import "Contacts.h"
#import <LKDBHelper.h>

@implementation Contacts

+ (NSString *)getTableName
{
    return @"IMContacts";
}

+ (NSDictionary *)getTableMapping
{
    return @{
             @"userId":@"userId",
             @"userRole":@"userRole",
             @"contactId":@"contactId",
             @"contactRole":@"contactRole",
             @"createTime":@"createTime",
             @"remarkName":@"remarkName",
             @"remarkHeader":@"remarkHeader",
             @"relation":@"relation"
             };
}

@end
