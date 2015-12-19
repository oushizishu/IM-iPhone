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
           if ([value isKindOfClass:[NSDictionary class]])
           {
               IMMessageBody *messageBody = nil;
               NSString *body = [value valueForKey:@"body"];
               if ([body length] == 0) return nil;
               NSInteger msg_t = [[value valueForKey:@"msg_t"] integerValue];
               NSDictionary *dictioanry = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
               
               NSError *error;
               switch (msg_t) {
                   case eMessageType_TXT:
                       messageBody = [IMTxtMessageBody modelWithDictionary:dictioanry error:&error];
                       break;
                   case eMessageType_IMG:
                       messageBody = [IMImgMessageBody modelWithDictionary:dictioanry error:&error];
                       break;
                   case eMessageType_AUDIO:
                       messageBody = [IMAudioMessageBody modelWithDictionary:dictioanry error:&error];
                       break;
                   case eMessageType_CARD:
                       messageBody = [IMCardMessageBody modelWithDictionary:dictioanry error:nil];
                       break;
                   case eMessageType_EMOJI:
                       messageBody = [IMEmojiMessageBody modelWithDictionary:dictioanry error:nil];
                       break;
                   case eMessageType_LOCATION:
                       messageBody = [IMLocationMessageBody modelWithDictionary:dictioanry error:&error];
                       break;
                   case eMessageType_NOTIFICATION:
                       messageBody = [IMNotificationMessageBody modelWithDictionary:dictioanry error:&error];
                       break;
                   case eMessageType_CMD:
                       messageBody = [IMCmdMessageBody modelWithDictionary:dictioanry error:&error];
                       break;
                   default:
                       break;
               }
               return messageBody;
           }
            return nil;
        }];
    }
    else if ([key isEqualToString:@"ext"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            return dic; // dictionary
        }];
    }
    else if ([key isEqualToString:@"msgId"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            NSString *result = [NSString stringWithFormat:@"%011ld", (long)[value integerValue]];
            return result;
        }];
    }
    return nil;
}

- (NSString *)sign
{
    if (! _sign)
    {
        _sign = [NSString stringWithFormat:@"%lld%lld", self.sender, (int64_t)[[NSDate date] timeIntervalSince1970]];
    }
    
    return _sign;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"msgId":@"msg_id",
             @"sender":@"sender",
             @"senderRole":@"sender_r",
             @"receiver":@"receiver",
             @"receiverRole":@"receiver_r",
             @"ext":@"ext",
             @"createAt":@"create_at",
             @"chat_t":@"chat_t",
             @"msg_t":@"msg_t",
             @"status":@"status",
             @"sign":@"sign",
             @"messageBody":@[@"body", @"msg_t"],
             };
}


+ (NSDictionary *)getTableMapping
{
    return @{@"msgId":@"msgId",
             @"sender":@"sender",
             @"senderRole":@"senderRole",
             @"receiver":@"receiver",
             @"receiverRole":@"receiverRole",
             @"ext":@"ext",
             @"createAt":@"createAt",
             @"chat_t":@"chat_t",
             @"msg_t":@"msg_t",
             @"status":@"status",
             @"read":@"read",
             @"played":@"played",
             @"sign":@"sign",
             @"conversationId":@"conversationId",
             @"messageBody":@"messageBody",
             };
}

@end
