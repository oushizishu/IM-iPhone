//
//  IMEmojiMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMEmojiMessageBody.h"

@implementation IMEmojiMessageBody

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
            @"type":@"type",
            @"content":@"content",
            @"name":@"name",
             };
}
@end
