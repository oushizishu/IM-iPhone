//
//  HandleDisbandGroupOperation.h
//  Pods
//
//  Created by 杨磊 on 15/8/14.
//
//

#import "IMBaseOperation.h"

@class BJIMService;

@interface HandleDisbandGroupOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, assign) int64_t groupId;
@end
