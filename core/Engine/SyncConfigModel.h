//
//  SyncConfigModel.h
//  Pods
//
//  Created by 杨磊 on 15/7/16.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

#import "User.h"

@interface SimpleUserModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger number;
@property (nonatomic, assign) NSInteger role;

@end

@interface SyncConfigModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray *polling_delta;
@property (nonatomic, assign) NSInteger *close_polling;

@property (nonatomic, strong) SimpleUserModel *administrators;
@property (nonatomic, strong) SimpleUserModel *customWaiter;
@property (nonatomic, strong) SimpleUserModel *systemSecretary;

@end
