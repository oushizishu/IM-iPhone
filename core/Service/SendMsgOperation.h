//
//  SendMsgOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import <Foundation/Foundation.h>
#import "IMBaseOperation.h"
#import "BJIMService.h"
#import "IMMessage.h"

@interface SendMsgOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong) IMMessage *message;

@end
