//
//  HandleGetMsgOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "HandlePollingResultOperation.h"

@interface HandleGetMsgOperation : HandlePollingResultOperation

@property (nonatomic, assign) NSInteger conversationId;

@end
