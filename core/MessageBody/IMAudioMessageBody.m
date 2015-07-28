//
//  IMAudioMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMAudioMessageBody.h"

@implementation IMAudioMessageBody

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"file":@"file",
            @"url":@"url",
             @"length":@"length"
             };
}

@end
