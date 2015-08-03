//
//  LoadRecentContactsOperation.h
//  Pods
//
//  Created by 杨磊 on 15/8/3.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@interface LoadRecentContactsOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;

@end
