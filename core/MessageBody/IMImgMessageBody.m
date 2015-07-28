//
//  IMImgMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMImgMessageBody.h"

@implementation IMImgMessageBody

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"file":@"file",
             @"url":@"url",
             @"width":@"width",
             @"height":@"height"
             };
}

@end
