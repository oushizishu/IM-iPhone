//
//  HistoryDirtyDataCleanOperation.h
//  Pods
//
//  Created by 杨磊 on 16/4/1.
//
//

#import  "IMBaseOperation.h"

@class BJIMService;
@interface HistoryDirtyDataCleanOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;

@end
