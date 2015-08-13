//
//  ResetConversationUnreadNumOperation.h
//  Pods
//
//  Created by 杨磊 on 15/8/13.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@class Conversation;
@interface ResetConversationUnreadNumOperation : IMBaseOperation

@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, weak) BJIMService *imService;

@end