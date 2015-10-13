//
//  PollingResultModel.m
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "PollingResultModel.h"
#import "IMMessage.h"
#import "User.h"

@implementation UnReadNum

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"group_id":@"group_id",
             @"num":@"num"
             };
}

@end

@implementation Info

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"firstMsgId":@"fid"
             };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"firstMsgId"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            NSString *result = [NSString stringWithFormat:@"%011ld", (long)[value integerValue]];
            return result;
        }];
    }
    return nil;
}
@end

@implementation PollingResultModel

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
   if ([key isEqualToString:@"msgs"])
   {
       return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
          if ([value isKindOfClass:[NSArray class]])
          {
              NSArray *array = [MTLJSONAdapter modelsOfClass:[IMMessage class] fromJSONArray:value error:nil];
              return array;
          }
           return nil;
       }];
   }
   else if ([key isEqualToString:@"users"])
   {
       return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
           
           if ([value isKindOfClass:[NSArray class]])
           {
               NSArray *array = [MTLJSONAdapter modelsOfClass:[User class] fromJSONArray:value error:error];
               return array;
           }
           return nil;
       }];
   }
    else if ([key isEqualToString:@"groups"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            
            if ([value isKindOfClass:[NSArray class]])
            {
                NSArray *array = [MTLJSONAdapter modelsOfClass:[Group class] fromJSONArray:value error:nil];
                return array;
            }
            return nil;
        }];
    }
    else if ([key isEqualToString:@"unread_number"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
           if ([value isKindOfClass:[NSArray class]])
           {
               NSArray *array = [MTLJSONAdapter modelsOfClass:[UnReadNum class] fromJSONArray:value error:nil];
               return array;
           }
            return nil;
        }];
    }
    else if ([key isEqualToString:@"info"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSDictionary class]])
            {
                Info *info = [MTLJSONAdapter modelOfClass:[Info class] fromJSONDictionary:value error:nil];
                return info;
            }
            return nil;
        }];
    }
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"msgs":@"msgs",
             @"users":@"users",
             @"groups":@"groups",
             @"unread_number":@"unread_number",
             @"ops":@"ops",
             @"info":@"info"
             };
}

@end
