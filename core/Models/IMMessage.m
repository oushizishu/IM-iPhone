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
               NSInteger msg_t = [[value valueForKey:@"msg_t"] integerValue];
               NSDictionary *dictioanry = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
               
               switch (msg_t) {
                   case eMessageType_TXT:
                       messageBody = [IMTxtMessageBody modelWithDictionary:dictioanry error:nil];
                       break;
                   case eMessageType_IMG:
                       messageBody = [IMImgMessageBody modelWithDictionary:dictioanry error:nil];
                       break;
                   case eMessageType_AUDIO:
                       messageBody = [IMAudioMessageBody modelWithDictionary:dictioanry error:nil];
                       break;
                   case eMessageType_LOCATION:
                       messageBody = [IMLocationMessageBody modelWithDictionary:dictioanry error:nil];
                       break;
                   case eMessageType_NOTIFICATION:
//                       messageBody = [];
                    
                       
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
    return nil;
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
@end
