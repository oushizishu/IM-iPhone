//
//  BJIMService.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "BJIMStorage.h"
#import "IMMessage.h"
#import "BJIMAbstractEngine.h"


@class BaseResponse;
@interface BJIMService : NSObject
@property (nonatomic, assign) BOOL bIsServiceActive;
@property (nonatomic, strong, readonly) BJIMAbstractEngine *imEngine;
@property (nonatomic, strong, readonly) BJIMStorage *imStorage;

@property (nonatomic, strong, readonly) NSOperationQueue *writeOperationQueue; // DB 写操作线程

- (void)startServiceWithOwner:(User *)owner;

- (void)stopService;

//- (void)removeOperationsWhileStopChat;

#pragma mark - 消息操作
- (void)sendMessage:(IMMessage *)message;
- (void)retryMessage:(IMMessage *)message;
- (void)loadMessagesUser:(User *)user orGroup:(Group *)group minMsgId:(NSString *)minMsgId;

#pragma mark - getter 
- (NSArray *)getAllConversationWithOwner:(User *)owner;
- (Conversation *)getConversationUserOrGroupId:(int64_t)userOrGroupId
                                      userRole:(IMUserRole)userRole
                                         ownerId:(int64_t)ownerId
                                     ownerRole:(IMUserRole)ownerRole
                                        chat_t:(IMChatType)chat_t;
- (void)insertConversation:(Conversation *)conversation;
- (void)resetConversationUnreadnum:(Conversation *)conversation;
- (NSInteger)getAllConversationUnReadNumWithUser:(User *)owner;
- (BOOL)deleteConversation:(Conversation *)conversation owner:(User *)owner;

- (User *)getUser:(int64_t)userId role:(IMUserRole)userRole;
- (void)setUser:(User *)user;
- (Group *)getGroup:(int64_t)groupId;

- (NSArray *)getGroupsWithUser:(User *)user;
- (NSArray *)getTeacherContactsWithUser:(User *)user;
- (NSArray *)getStudentContactsWithUser:(User *)user;
- (NSArray *)getInstitutionContactsWithUser:(User *)user;

- (void)addRecentContactId:(int64_t)userId
               contactRole:(IMUserRole)userRole
                  callback:(void(^)(BaseResponse *response))callback;

#pragma mark -系统小秘书 & 客服
//系统小秘书
- (User *)getSystemSecretary;
// 客服
- (User *)getCustomWaiter;

#pragma mark - remark name
- (void)setRemarkName:(NSString *)remarkName
                 user:(User *)user
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

- (void)setRemarkName:(NSString *)remarkName
                group:(Group *)group
             callback:(void(^)(NSString *remarkName, NSInteger errCode, NSString *errMsg))callback;

// 判断该老师是否为我的老师：(to学生端)
- (BOOL)hasTeacher:(int64_t)teacherId ofUser:(User *)user;
// 判断该机构是否为我的机构:(to学生端)
- (BOOL)hasInsitituion:(int64_t)institutionId ofUser:(User *)user;
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
- (void)notifyPreLoadMessages:(NSArray *)messages conversation:(Conversation *)conversation;
- (void)notifyLoadMoreMessages:(NSArray *)messages conversation:(Conversation *)conversation hasMore:(BOOL)hasMore;

- (void)addRecentContactsDelegate:(id<IMRecentContactsDelegate>)delegate;
- (void)notifyRecentContactsChanged:(NSArray *)contacts;

- (void)addUserInfoChangedDelegate:(id<IMUserInfoChangedDelegate>)delegate;
- (void)notifyUserInfoChanged:(User *)user;

- (void)addGroupProfileChangedDelegate:(id<IMGroupProfileChangedDelegate>)delegate;
- (void)notifyGroupProfileChanged:(Group *)group;

- (void)addDisconnectionDelegate:(id<IMDisconnectionDelegate>)delegate;

- (void)addLoginLogoutDelegate:(id<IMLoginLogoutDelegate>)delegate;
- (void)notifyIMLoginFinish;
- (void)notifyIMLogoutFinish;

@end
