//
//  RetrySendMsgOperation.h
//  Pods
//
//  Created by 彭碧 on 15/7/21.
//
//

#import "IMBaseOperation.h"
@class BJIMService;
@class IMMessage;
@interface RetrySendMsgOperation : IMBaseOperation
@property(nonatomic,weak) BJIMService *imService;
@property(nonatomic,strong)IMMessage *message;
@end
