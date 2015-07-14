//
//  User.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "User.h"

@implementation User

+ (NSString *)getTableName
{
    return @"USERS";
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
      @"userId":@"user_id",
      @"userRole":@"user_role",
      @"name":@"name",
      };
}
@end
