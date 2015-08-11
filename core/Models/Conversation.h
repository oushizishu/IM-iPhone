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
#import "LKDBHelper.h"

@interface Conversation : NSObject

@property (nonatomic, assign) int64_t ownerId;
@property (nonatomic, assign) IMUserRole ownerRole;
@property (nonatomic, assign) int64_t toId;
@property (nonatomic, assign) IMUserRole toRole;
@property (nonatomic, assign) double_t lastMessageId;
@property (nonatomic, assign) IMChatType chat_t;
@property (nonatomic, assign) NSInteger unReadNum;

@property (nonatomic, assign) NSInteger status; // 0 正常， 1 已删除

- (instancetype)initWithOwnerId:(int64_t)ownerId
                      ownerRole:(IMUserRole)ownerRole
                           toId:(int64_t)toId
                         toRole:(IMUserRole)toRole
                  lastMessageId:(double_t)lastMessageId
                       chatType:(IMChatType)chatType;

@end
