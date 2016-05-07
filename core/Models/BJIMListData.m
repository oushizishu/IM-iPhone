//
//  BJIMListData.m
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import "BJIMListData.h"
#import "IMJSONAdapter.h"

static int ddLogLevel = DDLogLevelVerbose;

@implementation BJIMListData

+ (NSString *)modelClassStr;
{
    return nil;
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"hasMore"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value boolValue]);
        }];
    }
    else if ([key isEqualToString:@"list"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]]) {
                if ([self modelClassStr]) {
                    return [IMJSONAdapter modelsOfClass:NSClassFromString([self modelClassStr]) fromJSONArray:value error:error];
                }
                return value;
            }
            else
                DDLogError(@"jsonModel trans fail value的类型不对");
            return nil;
        }];
    }
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"list":@"list",
             @"hasMore":@"has_more"};
}
@end
