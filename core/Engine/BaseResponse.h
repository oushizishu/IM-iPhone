//
//  BaseResponse.h
//  Pods
//
//  Created by 杨磊 on 15/7/15.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

#define IMSDK_ERROR_CODE_NATIVE_NOT_FOUND         -404

@interface BaseResponse : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, assign) NSString *msg;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) NSInteger ts;

- (instancetype)initWithErrorCode:(NSInteger)code
                         errorMsg:(NSString *)msg;

- (id)arrayData;
- (id)dictionaryData;
@end
