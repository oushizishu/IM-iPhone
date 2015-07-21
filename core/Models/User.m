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
      @"userId":@"user_number",
      @"userRole":@"user_role",
      @"name":@"user_name",
      @"avatar":@"avatar",
      };
}
@end
