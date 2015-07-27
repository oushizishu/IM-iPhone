//
//  IMMessageBody.m
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMMessageBody.h"

@implementation IMMessageBody

- (NSString *)description
{
    NSError *error ;
    NSDictionary *dic = [MTLJSONAdapter JSONDictionaryFromModel:self error:nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if (! data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
