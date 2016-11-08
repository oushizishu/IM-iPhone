//
//  AutoResponseList.m
//  Pods
//
//  Created by 杨磊 on 2016/10/28.
//
//

#import "AutoResponseList.h"
#import "IMJSONAdapter.h"

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

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"list"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]])
            {
                NSArray *array = [IMJSONAdapter modelsOfClass:[AutoResponseItem class] fromJSONArray:value error:nil];
                return array;
            }
            return nil;
        }];
    }
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"setting":@"setting",
             @"list" : @"list"
             };
}

@end
