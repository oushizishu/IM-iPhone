//
//  BJIMService.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "BJIMEngine.h"
#import "BJIMStorage.h"
#import "IMMessage.h"


@interface BJIMService : NSObject

@property (nonatomic, strong, readonly) BJIMEngine *imEngine;
@property (nonatomic, strong, readonly) BJIMStorage *imStorage;

- (void)startServiceWithOwner:(User *)owner;

- (void)stopService;

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message;
- (void)retryMessage:(IMMessage *)message;
- (void)loadMessages:(Conversation *)conversation minMsgId:(double_t)minMsgId;

#pragma mark - getter 
- (NSArray *)getAllConversationWithOwner:(User *)owner;
- (Conversation *)getConversationUserOrGroupId:(int64_t)userOrGroupId
                                      userRole:(IMUserRole)userRole
                                         owner:(User *)owner
                                        chat_t:(IMChatType)chat_t;

- (BOOL)deleteConversation:(Conversation *)conversation owner:(User *)owner;

- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole;
- (void)setUser:(User *)user;
- (Group *)getGroup:(int64_t)groupId;

- (NSArray *)getGroupsWithUser:(User *)user;
- (NSArray *)getTeacherContactsWithUser:(User *)user;
- (NSArray *)getStudentContactsWithUser:(User *)user;
- (NSArray *)getInstitutionContactsWithUser:(User *)user;
- (void)getRecentContactsWithUser:(User *)user;

//cache 相关
- (void)updateCacheUser:(User *)user;
- (void)updateCacheGroup:(Group *)group;

- (void)applicationEnterBackground;
- (void)applicationEnterForeground;

#pragma mark - add Delegates
- (void)addConversationChangedDelegate:(id<IMConversationChangedDelegate>)delegate;
- (void)notifyConversationChanged;

- (void)addReceiveNewMessageDelegate:(id<IMReceiveNewMessageDelegate>)delegate;
- (void)notifyReceiveNewMessages:(NSArray *)newMessages;

- (void)addDeliveryMessageDelegate:(id<IMDeliveredMessageDelegate>)delegate;
- (void)notifyDeliverMessage:(IMMessage *)message errorCode:(NSInteger)errorCode error:(NSString *)errorMsg;

- (void)addCmdMessageDelegate:(id<IMCmdMessageDelegate>)delegate;
- (void)notifyCmdMessages:(NSArray *)cmdMessages;

- (void)addContactChangedDelegate:(id<IMContactsChangedDelegate>)delegate;
- (void)notifyContactChanged;

- (void)addLoadMoreMessagesDelegate:(id<IMLoadMessageDelegate>)delegate;
- (void)notifyLoadMoreMessages:(NSArray *)messages conversation:(Conversation *)conversation hasMore:(BOOL)hasMore;

- (void)addRecentContactsDelegate:(id<IMRecentContactsDelegate>)delegate;
- (void)notifyRecentContactsChanged:(NSArray *)contacts;
@end
