//
//  AutoResponseList.m
//  Pods
//
//  Created by 杨磊 on 2016/10/28.
//
//

#import "AutoResponseList.h"

@implementation AutoResponseSetting

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"enable"      :@"enable",
             @"contentId" :@"content_id"
             };
}

@end

@implementation AutoResponseItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"contentId"      :@"id",
             @"selected" :@"selected",
             @"content" : @"content",
             @"createTime" :@"create_time"
             };
}

@end


@implementation AutoResponseList

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"setting":@"setting",
             @"list" : @"list"
             };
}

@end
