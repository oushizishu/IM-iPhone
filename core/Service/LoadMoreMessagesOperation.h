//
//  LoadMoreMessagesOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@class User;
@class Group;
@interface LoadMoreMessagesOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
//@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, strong) User *chatToUser;
@property (nonatomic, strong) Group *chatToGroup;

@property (nonatomic, copy) NSString *minMsgId;

@end
