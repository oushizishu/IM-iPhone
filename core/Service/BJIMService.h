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
@property (nonatomic, assign) BOOL bIsServiceActive;
@property (nonatomic, strong, readonly) BJIMEngine *imEngine;
@property (nonatomic, strong, readonly) BJIMStorage *imStorage;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;


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

- (NSInteger)getAllConversationUnReadNumWithUser:(User *)owner;
- (BOOL)deleteConversation:(Conversation *)conversation owner:(User *)owner;

- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole;
- (Group *)getGroup:(int64_t)groupId;
- (User *)getUserFromCache:(int64_t)userId role:(IMUserRole)userRole;
- (Group *)getGroupFromCache:(int64_t)groupId;
- (void)insertUserToCache:(User *)user;
- (void)insertGroupToCache:(Group *)group;

- (NSArray *)getGroupsWithUser:(User *)user;
- (NSArray *)getTeacherContactsWithUser:(User *)user;
- (NSArray *)getStudentContactsWithUser:(User *)user;
- (NSArray *)getInstitutionContactsWithUser:(User *)user;

#pragma mark -系统小秘书 & 客服
//系统小秘书
- (User *)getSystemSecretary;
// 客服
- (User *)getCustomWaiter;

//cache 相关
- (void)updateCacheUser:(User *)user;
- (void)updateCacheGroup:(Group *)group;

#pragma mark - remark name
- (void)setRemarkName:(NSString *)remarkName
                 user:(User *)user
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

- (void)setRemarkName:(NSString *)remarkName
                group:(Group *)group
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

// 判断该老师是否为我的老师：(to学生端)
- (BOOL)hasTeacher:(int64_t)teacherId ofUser:(User *)user;
- (GroupMember *)getGroupMember:(int64_t)groupId ofUser:(User *)user;

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

- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate;
- (void)notifyUserInfoChanged:(User *)user;

- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate;
- (void)notifyGroupProfileChanged:(Group *)group;

@end
