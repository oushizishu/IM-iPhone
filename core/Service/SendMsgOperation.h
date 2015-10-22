//
//  SendMsgOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMBaseOperation.h"
@class BJIMService;
@class IMMessage;

@interface SendMsgOperation : IMBaseOperation
@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong)IMMessage *message;
@property (nonatomic, strong)NSMutableArray *remindMessageArray;
@property (nonatomic)BOOL ifRefuse;

@end
