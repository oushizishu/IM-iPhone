//
//  IMCmdMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/29.
//
//

#import "IMCmdMessageBody.h"

@implementation IMCmdMessageBody

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"type":@"type",
             @"payload":@"payload"
             };
}

@end
