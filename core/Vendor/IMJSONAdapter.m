//
//  LPJSONAdapter.m
//  Pods
//
//  Created by Randy on 16/4/8.
//
//

#import "IMJSONAdapter.h"

static NSString *const LPFloatValueTransformerName = @"LPFloatValueTransformerName";
static NSString *const LPDoubleValueTransformerName = @"LPDoubleValueTransformerName";
static NSString *const LPIntValueTransformerName = @"LPIntValueTransformerName";
static NSString *const LPLongValueTransformerName = @"LPLongValueTransformerName";
static NSString *const LPLongLongValueTransformerName = @"LPLongLongValueTransformerName";
static NSString *const LPUnsignLongValueTransformerName = @"LPUnsignLongValueTransformerName";
static NSString *const LPUnsignIntValueTransformerName = @"LPUnsignIntValueTransformerName";

@implementation IMJSONAdapter

+ (NSError *)LP_transformerValueError:(id)value objCType:(const char *)objCType
{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert to number or vice-versa", @""),
                               NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an %s, got: %@.", @""),objCType, value],
                               MTLTransformerErrorHandlingInputValueErrorKey : value
                               };
    return [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
}

+ (void)loadTransformerValueWithName:(NSString *)name objCType:(const char *)objCType
{
    MTLValueTransformer *valueTransformer = [MTLValueTransformer transformerUsingForwardBlock:^id(NSNumber *value, BOOL *success, NSError *__autoreleasing *error) {
        if (value == nil) return nil;
        if ([value isKindOfClass:NSNumber.class])
            return value;
        else if([value isKindOfClass:NSString.class])
        {
            NSString *stringValue = (NSString *)value;
           if(strcmp(objCType, @encode(float)) == 0){
                return @([stringValue floatValue]);
            }
            else if(strcmp(objCType, @encode(double)) == 0){
                return @([stringValue doubleValue]);
            }
            else if(strcmp(objCType, @encode(int)) == 0){
                return @([stringValue intValue]);
            }
            else if(strcmp(objCType, @encode(long)) == 0){
                //TODO longValue
                return @([stringValue longLongValue]);
            }
            else if(strcmp(objCType, @encode(long long)) == 0){
                return @([stringValue longLongValue]);
            }
            else if(strcmp(objCType, @encode(unsigned long)) == 0){
                return @([stringValue integerValue]);
            }
            else if(strcmp(objCType, @encode(unsigned int)) == 0){
                return @([stringValue integerValue]);
            }

            if (error != NULL) {
                *error = [self LP_transformerValueError:stringValue objCType:objCType];
            }
            *success = NO;
            return nil;
        }
        else
        {
            if (error != NULL) {
                *error = [self LP_transformerValueError:value objCType:objCType];
            }
            *success = NO;
            return nil;
        }
    }];
    
    [NSValueTransformer setValueTransformer:valueTransformer forName:name];
}

+ (void)load{
    [self loadTransformerValueWithName:LPIntValueTransformerName objCType:@encode(int)];
    [self loadTransformerValueWithName:LPFloatValueTransformerName objCType:@encode(float)];
    [self loadTransformerValueWithName:LPDoubleValueTransformerName objCType:@encode(double)];
    [self loadTransformerValueWithName:LPLongValueTransformerName objCType:@encode(long)];
    [self loadTransformerValueWithName:LPLongLongValueTransformerName objCType:@encode(long long)];
    [self loadTransformerValueWithName:LPUnsignLongValueTransformerName objCType:@encode(unsigned long)];
    [self loadTransformerValueWithName:LPUnsignIntValueTransformerName objCType:@encode(unsigned int)];
}

+ (NSValueTransformer *)NSStringJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if (value && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
            return [NSString stringWithFormat:@"%@",value];
        }
        return nil;
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}


+ (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType;
{
    NSValueTransformer *transformer = [super transformerForModelPropertiesOfObjCType:objCType];
    if (transformer) {
        return transformer;
    }
    else if(strcmp(objCType, @encode(float)) == 0){
        return [NSValueTransformer valueTransformerForName:LPFloatValueTransformerName];
    }
    else if(strcmp(objCType, @encode(double)) == 0){
        return [NSValueTransformer valueTransformerForName:LPDoubleValueTransformerName];
    }
    else if(strcmp(objCType, @encode(int)) == 0){
        return [NSValueTransformer valueTransformerForName:LPIntValueTransformerName];
    }
    else if(strcmp(objCType, @encode(long long)) == 0){
        return [NSValueTransformer valueTransformerForName:LPLongLongValueTransformerName];
    }
    else if(strcmp(objCType, @encode(long)) == 0){
        return [NSValueTransformer valueTransformerForName:LPLongValueTransformerName];
    }
    else if (strcmp(objCType, @encode(unsigned long)) == 0) {
        return [NSValueTransformer valueTransformerForName:LPUnsignLongValueTransformerName];
    }
    else if (strcmp(objCType, @encode(unsigned int)) == 0) {
        return [NSValueTransformer valueTransformerForName:LPUnsignIntValueTransformerName];
    }
    return nil;
}


@end
