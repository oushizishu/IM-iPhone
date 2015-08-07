//
//  GroupMemberListData.m
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import "GroupMemberListData.h"
#import "User.h"

@implementation GroupMemberListData
+ (NSString *)modelClassStr;
{
    return NSStringFromClass([User class]);
}
@end
