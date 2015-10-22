//
//  RetryMessageOperation.h
//  Pods
//
//  Created by 杨磊 on 15/8/8.
//
//

#import "IMBaseOperation.h"

@class IMMessage;
@class BJIMService;
@interface RetryMessageOperation : IMBaseOperation

@property (nonatomic, strong) IMMessage *message;
@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong)NSMutableArray *remindMessageArray;
@property (nonatomic)BOOL ifRefuse;
@end
