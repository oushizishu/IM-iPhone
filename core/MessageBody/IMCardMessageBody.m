//
//  IMCardMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMCardMessageBody.h"

@implementation IMCardMessageBody

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"title":@"title",
             @"content":@"content",
             @"url":@"url",
             @"thumb":@"thumb",
             @"number":@"number",
             @"type":@"type",
             };
}

@end
