//
//  SendMsgModel.m
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import "SendMsgModel.h"

@implementation SendMsgModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
            @"msgId":@"msg_id",
            @"createAt":@"create_at"
             };
}

@end
