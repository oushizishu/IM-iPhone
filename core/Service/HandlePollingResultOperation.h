//
//  HandlePollingResultOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@class PollingResultModel;

@interface HandlePollingResultOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, copy) PollingResultModel *model;

@end
