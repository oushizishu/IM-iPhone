//
//  IMNotificationMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/29.
//
//

#import "IMNotificationMessageBody.h"

@implementation IMNotificationMessageBody

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"type":@"type",
             @"content":@"content",
             @"action":@"action"
             };
}

@end
