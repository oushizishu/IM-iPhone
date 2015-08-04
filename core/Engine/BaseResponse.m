//
//  BaseResponse.m
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import "BaseResponse.h"

@implementation BaseResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"code":@"code",
             @"msg":@"msg",
             @"data":@"data",
             @"ts":@"ts"
             };
}

- (id)data
{
    if ([_data isKindOfClass:[NSDictionary class]] ||
        [_data isKindOfClass:[NSArray class]]) {
        return _data;
    }
    
    return nil;
}
@end
