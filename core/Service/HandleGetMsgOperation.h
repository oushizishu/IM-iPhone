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
@property (nonatomic, assign) NSString *minMsgId;
@property (nonatomic, copy) NSString *endMessageId;

@end
