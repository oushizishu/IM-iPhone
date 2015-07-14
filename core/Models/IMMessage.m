//
//  IMMessage.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "IMMessage.h"

@implementation IMMessage

+ (NSString *)getTableName
{
    return @"IMMESSAGE";
}

+ (NSValueTransformer*)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"messageBody"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
           if ([value isKindOfClass:[NSArray class]])
           {
               IMMessageBody *messageBody = nil;
               return messageBody;
           }
            return nil;
        }];
    }
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"body":@"body",
             @"messageBody":@[@"body", @"msg_t"],
             };
}
@end
