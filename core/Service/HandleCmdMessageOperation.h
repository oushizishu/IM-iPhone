//
//  HandleCmdMessageOperation.h
//  Pods
//
//  Created by 杨磊 on 15/11/3.
//
//

#import "IMBaseOperation.h"
#import "IMMessage.h"
#import "BJIMService.h"

@interface HandleCmdMessageOperation : IMBaseOperation

@property (nonatomic, strong) IMMessage *message;
@property (nonatomic, weak) BJIMService *imService;

@end
