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

@property (nonatomic, assign) double mstId;
@property (nonatomic, assign) int64_t createAt;

@end