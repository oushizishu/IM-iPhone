//
//  ResetMsgIdOperation.h
//  Pods
//
//  Created by 杨磊 on 15/8/25.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@interface ResetMsgIdOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@end
