//
//  BaseResponse.m
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import "BaseResponse.h"

static int ddLogLevel = DDLogLevelVerbose;

@implementation BaseResponse

- (instancetype)initWithErrorCode:(NSInteger)code errorMsg:(NSString *)msg
{
    self = [super init];
    if (self) {
        self.code = code;
        self.msg = msg;
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"code":@"code",
             @"msg":@"msg",
             @"data":@"data",
             @"ts":@"ts"
             };
}

- (id)dictionaryData
{
    if ([_data isKindOfClass:[NSDictionary class]]) {
        return _data;
    }
    else if (_data)
    {
        DDLogError(@"返回数据类型不对 [data:%@]",_data);
        NSAssert1(0, @"返回数据类型不对 [data:%@]", _data);
        return nil;
    }
    return nil;
}

- (id)arrayData
{
    if ([_data isKindOfClass:[NSArray class]]) {
        return _data;
    }
    else if (_data)
    {
        DDLogError(@"返回数据类型不对 [data:%@]",_data);
        NSAssert1(0, @"返回数据类型不对 [data:%@]", _data);
        return nil;
    }
    return nil;
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
