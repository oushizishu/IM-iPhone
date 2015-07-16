//
//  SyncConfigModel.h
//  Pods
//
//  Created by 杨磊 on 15/7/16.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface SyncConfigModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray *polling_delta;
@property (nonatomic, assign) NSInteger *close_polling;

@end
