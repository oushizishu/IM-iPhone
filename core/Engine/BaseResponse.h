//
//  BaseResponse.h
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface BaseResponse : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, assign) NSString *msg;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) NSInteger ts;


- (id)arrayData;
- (id)dictionaryData;
@end
