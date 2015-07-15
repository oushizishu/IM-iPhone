//
//  BaseResponse.h
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

#define RESULT_CODE_SUCC 0

@interface BaseResponse : MTLJSONAdapter<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, assign) NSString *msg;
@property (nonatomic, strong) NSDictionary *data;

@end
