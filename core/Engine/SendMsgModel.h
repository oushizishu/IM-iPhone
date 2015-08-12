//
//  SendMsgModel.h
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface SendMsgModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *msgId;
@property (nonatomic, assign) int64_t createAt;
@property (nonatomic, copy) NSString *body;

@end
