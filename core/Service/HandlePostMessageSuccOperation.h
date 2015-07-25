//
//  HandlePostMessageSuccOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/21.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@class IMMessage;
@class SendMsgModel;
@interface HandlePostMessageSuccOperation : IMBaseOperation

@property (nonatomic, strong) IMMessage *message;
@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong) SendMsgModel *model;

@end
