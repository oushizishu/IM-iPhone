//
//  SendMsgModel.m
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import "SendMsgModel.h"

@implementation SendMsgModel

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"msgId"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            return @([value doubleValue]);
        }];
    }
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
            @"msgId":@"msg_id",
            @"createAt":@"create_at",
            @"body":@"body"
             };
}

@end
