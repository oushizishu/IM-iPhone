//
//  PrePollingOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/21.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@interface PrePollingOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;

@end
