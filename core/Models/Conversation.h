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

@interface Conversation : NSObject

@property (nonatomic, assign) int64_t conversation_id;
@property (nonatomic, assign) int64_t owner_id;
@property (nonatomic, assign) IMUserRole owner_role;
@property (nonatomic, assign) int64_t to_id;
@property (nonatomic, assign) IMUserRole to_role;
@property (nonatomic, assign) int64_t last_msg_id;
@property (nonatomic, assign) IMChatType chat_t;
@property (nonatomic, assign) NSInteger unread_num;

@property (nonatomic, strong, readonly) User *chatToUser;
@property (nonatomic, strong, readonly) Group *chatToGroup;

@end
