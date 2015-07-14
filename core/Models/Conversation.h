//
//  Conversation.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "User.h"
#import "Group.h"

@interface Conversation : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t ownerId;
@property (nonatomic, assign) IMUserRole ownerRole;
@property (nonatomic, assign) int64_t toId;
@property (nonatomic, assign) IMUserRole toRole;
@property (nonatomic, assign) int64_t lastMsgRawId;
@property (nonatomic, assign) IMChatType chat_t;
@property (nonatomic, assign) NSInteger unReadNum;

@property (nonatomic, strong, readonly) User *chatToUser;
@property (nonatomic, strong, readonly) Group *chatToGroup;

@end
