//
//  Conversation+DB.h
//  Pods
//
//  Created by 杨磊 on 15/7/20.
//
//

#import <Foundation/Foundation.h>
#import "Conversation.h"

@class BJIMService;
@class IMMessage;
@interface Conversation(DB)

@property (nonatomic,weak) BJIMService *imService;

@property (nonatomic, strong, readonly) User *chatToUser;
@property (nonatomic, strong, readonly) Group *chatToGroup;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong, readonly)IMMessage *lastMessage;

@end
