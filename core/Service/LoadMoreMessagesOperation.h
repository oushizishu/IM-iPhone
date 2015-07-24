//
//  LoadMoreMessagesOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@class Conversation;
@interface LoadMoreMessagesOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, assign) double_t minMsgId;

@end
