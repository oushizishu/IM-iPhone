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

#import "GroupDetail.h"
#import <BJHL-Common-iOS-SDK/BJNetworkUtil.h>


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

- (void)getGroupDetail:(int64_t)groupId callback:(void(^)(NSError *error ,GroupDetail *groupDetail))callback;

- (void)getGroupMembers:(int64_t)groupId page:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void(^)(NSError *error ,NSArray *members,BOOL hasMore,BOOL is_admin,BOOL is_major))callback;

- (void)transferGroup:(int64_t)groupId
          transfer_id:(int64_t)transfer_id
        transfer_role:(int64_t)transfer_role
             callback:(void(^)(NSError *error))callback;

- (void)setGroupAvatar:(int64_t)groupId
                avatar:(int64_t)avatar
              callback:(void(^)(NSError *error))callback;

- (void)setGroupAdmin:(int64_t)groupId
          user_number:(int64_t)user_number
            user_role:(int64_t)user_role
               status:(int64_t)status
             callback:(void(^)(NSError *error))callback;

- (void)removeGroupMember:(int64_t)groupId
              user_number:(int64_t)user_number
                user_role:(int64_t)user_role
                 callback:(void(^)(NSError *error))callback;

- (void)postLeaveGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;

- (void)postDisBandGroup:(int64_t)groupId callback:(void (^)(NSError *err))callback;

- (void)getGroupFiles:(int64_t)groupId
         last_file_id:(int64_t)last_file_id
             callback:(void(^)(NSError *error ,NSArray<GroupFile *> *list))callback;

- (BJNetRequestOperation*)uploadGroupFile:(NSString*)attachment
                                 filePath:(NSString*)filePath
                                 fileName:(NSString*)fileName
                                 callback:(void(^)(NSError *error ,int64_t storage_id))callback
                                 progress:(onProgress)progress;

- (void)addGroupFile:(int64_t)groupId
          storage_id:(int64_t)storage_id
            fileName:(NSString*)fileName
            callback:(void(^)(NSError *error ,GroupFile *groupFile))callback;

- (BJNetRequestOperation*)downloadGroupFile:(NSString*)fileUrl
                                   filePath:(NSString*)filePath
                                   callback:(void(^)(NSError *error))callback
                                   progress:(onProgress)progress;

- (void)previewGroupFile:(int64_t)groupId
                 file_id:(int64_t)file_id
                callback:(void(^)(NSError *error ,NSString *url))callback;

- (void)setGroupMsgStatus:(int64_t)status
                  groupId:(int64_t)groupId
                 callback:(void(^)(NSError *error))callback;

- (void)deleteGroupFile:(int64_t)groupId
                file_id:(int64_t)file_id
               callback:(void(^)(NSError *error))callback;

-(void)createGroupNotice:(int64_t)groupId
                 content:(NSString*)content
                callback:(void(^)(NSError *error))callback;

-(void)getGroupNotice:(int64_t)groupId
              last_id:(int64_t)last_id
            page_size:(int64_t)page_size
             callback:(void(^)(NSError *error ,BOOL isAdmin ,NSArray<GroupNotice*> *list ,BOOL hasMore))callback;

-(void)removeGroupNotice:(int64_t)notice_id
                callback:(void(^)(NSError *error))callback;

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

- (void)addNewGroupNoticeDelegate:(id<IMNewGRoupNoticeDelegate>)delegate;
- (void)notifyNewGroupNotice;

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
