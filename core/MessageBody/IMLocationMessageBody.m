//
//  IMLocationMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMLocationMessageBody.h"

@implementation IMLocationMessageBody

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
                @"lat":@"lat",
                @"lng":@"lng",
                @"address":@"address"
             };
}

@end
