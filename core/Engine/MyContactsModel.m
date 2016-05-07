//
//  MyContactsModel.m
//  Pods
//
//  Created by 杨磊 on 15/7/25.
//
//

#import "MyContactsModel.h"
#import "User.h"
#import "Group.h"
#import "IMJSONAdapter.h"

@implementation MyContactsModel

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"teacherList"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
           if ([value isKindOfClass:[NSArray class]])
           {
               NSError *error;
               NSArray *array = [IMJSONAdapter modelsOfClass:[User class] fromJSONArray:value error:&error];
               return array;
           }
            return nil;
        }];
    }
    else if ([key isEqualToString:@"organizationList"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]])
            {
                NSError *error;
                NSArray *array = [IMJSONAdapter modelsOfClass:[User class] fromJSONArray:value error:&error];
                return array;
            }
            return nil;
        }];
    }
    else if ([key isEqualToString:@"studentList"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]])
            {
                NSError *error;
                NSArray *array = [IMJSONAdapter modelsOfClass:[User class] fromJSONArray:value error:&error];
                return array;
            }
            return nil;
        }];
    }
    else if ([key isEqualToString:@"groupList"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
           if ([value isKindOfClass:[NSArray class]])
           {
               NSError *error ;
               NSArray *array = [IMJSONAdapter modelsOfClass:[Group class] fromJSONArray:value error:&error];
               return array;
           }
            return nil;
        }];
    }
    else if ([key isEqualToString:@"blackList"])
    {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSArray class]])
            {
                NSError *error ;
                NSArray *array = [IMJSONAdapter modelsOfClass:[User class] fromJSONArray:value error:&error];
                return array;
            }
            return nil;
        }];
    }
    
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
            @"teacherList"      :@"teacher_list",
            @"organizationList" :@"organization_list",
            @"studentList"      :@"student_list",
            @"groupList"        :@"group_list",
            @"blackList"        :@"black_list",
             };
}

@end
