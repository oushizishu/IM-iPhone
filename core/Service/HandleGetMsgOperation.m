//
//  HandleGetMsgOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "HandleGetMsgOperation.h"
#import "Conversation+DB.h"
#import "BJIMService.h"
#import "Group.h"
#import "IMMessage+DB.h"
#import "IMEnvironment.h"

@interface HandleGetMsgOperation()

@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) NSMutableArray *remindMessageArray;

@end

@implementation HandleGetMsgOperation

- (void)doOperationOnBackground
{
    if (self.imService == nil) return;
    if (self.model) {
        [super doOperationOnBackground];
    }
    
    IMChatType chatType = self.groupId > 0 ? eChatType_GroupChat : eChatType_Chat;
    User *owner = [IMEnvironment shareInstance].owner;
    
    self.conversation = [self.imService.imStorage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:chatType == eChatType_Chat?self.userId : self.groupId userRole:self.userRole chatType:chatType];
    
    if (! self.conversation) {
        // 之前两个人没有聊过。如果没有关注对方，则插入“点击关注”提示消息
        if (chatType == eChatType_Chat) {
            [self checkAndInsertHintAttentionMessage];
        }
        return;
    }
    
    self.conversation.imService = self.imService;
    
    NSString *__minMsgId = self.minMsgId;
    if (__minMsgId == nil) {
        NSString *maxConversationMsgId = [self.imService.imStorage.messageDao queryMaxMsgIdInConversation:self.conversation.rowid];
        __minMsgId = [NSString stringWithFormat:@"%015.4lf", [maxConversationMsgId doubleValue] + 0.0001];
    }
    
    if (self.model != nil) {
        self.conversation.firstMsgId = self.model.info.firstMsgId;
        [self.imService.imStorage.conversationDao update:self.conversation];
    }
    
    self.messages = [self.imService.imStorage.messageDao loadMoreMessageWithConversationId:self.conversation.rowid minMsgId:__minMsgId];
    
    if ([self.messages count] == 0) {
        self.hasMore = NO;
    } else if ([self.messages count] > 0 && [[[self.messages objectAtIndex:0] msgId] isEqualToString:self.conversation.firstMsgId]) {
        self.hasMore = NO;
    } else {
        self.hasMore = YES;
    }
    
    [self.messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IMMessage *__message = (IMMessage *)obj;
        __message.imService = self.imService;
    }];

    // 处理关注提示消息
    if (self.conversation.chat_t == eChatType_Chat && [self.messages count] == 0 && self.isFirstGetMsg) {
        // 单聊，第一次加载并且两人之间没有聊过天。才出现“点击关注”的提示消息。 如果已经聊过， 默认之前已经显示过这个消息了
        [self checkAndInsertHintAttentionMessage];
    }
}

- (void)doAfterOperationOnMain
{
    if (self.conversation)
        [self.imService notifyLoadMoreMessages:self.messages conversation:self.conversation hasMore:self.hasMore];
    
    if ([self.remindMessageArray count] > 0)
    {
        [self.imService notifyReceiveNewMessages:self.remindMessageArray];
        [self.imService notifyConversationChanged];
    }
}

- (void)checkAndInsertHintAttentionMessage
{
    User *owner = [IMEnvironment shareInstance].owner;
    User *contact = [self.imService.imStorage.userDao loadUser:self.userId role:self.userRole];
    
    SocialContacts *social = [self.imService.imStorage.socialContactsDao loadContactId:contact.userId contactRole:contact.userRole ownerId:owner.userId ownerRole:owner.userRole];
    if (! social || social.focusType == eIMFocusType_None || social.focusType == eIMFocusType_Passive) {
        // 没有关注对方
        if (self.conversation == nil) {
            self.conversation = [[Conversation alloc] initWithOwnerId:owner.userId ownerRole:owner.userRole toId:contact.userId toRole:contact.userRole lastMessageId:@"" chatType:eChatType_Chat];
            
            // TODO 判断陌生人关系，设置 relation 字段
            
            [self.imService.imStorage.conversationDao insert:self.conversation];
        }
        
        NSString *sign = @"HERMES_MESSAGE_NOFOCUS_SIGN";
        NSString *remindAttentionMsgId = [self.imService.imStorage.messageDao querySignMsgIdInConversation:self.conversation.rowid withSing:sign];
        
        if (remindAttentionMsgId == nil) {
            IMNotificationMessageBody *messageBody = [[IMNotificationMessageBody alloc] init];
            messageBody.content = [NSString stringWithFormat:@"<p><a href=\"hermes://o.c?a=addAttention@userNumber=%lld&amp;userRole=%ld\">点此关注对方，</a>可以在我的关注中找到对方哟</p>",contact.userId,contact.userRole];
            messageBody.type = eTxtMessageContentType_RICH_TXT;
            IMMessage *remindAttentionMessage = [[IMMessage alloc] init];
            remindAttentionMessage.messageBody = messageBody;
            remindAttentionMessage.createAt = [NSDate date].timeIntervalSince1970;
            remindAttentionMessage.chat_t = eChatType_Chat;
            remindAttentionMessage.msg_t = eMessageType_NOTIFICATION;
            remindAttentionMessage.receiver = owner.userId;
            remindAttentionMessage.receiverRole = owner.userRole;
            remindAttentionMessage.sender = contact.userId;
            remindAttentionMessage.senderRole = contact.userRole;
            remindAttentionMessage.msgId = [NSString stringWithFormat:@"%015.3lf", [[self.imService.imStorage.messageDao queryAllMessageMaxMsgId] doubleValue] + 0.001];
            remindAttentionMessage.sign = sign;
            remindAttentionMessage.conversationId = self.conversation.rowid;
            remindAttentionMessage.status = eMessageStatus_Send_Succ;
            
            self.conversation.lastMessageId = remindAttentionMessage.msgId;
            
            [self.imService.imStorage.messageDao insert:remindAttentionMessage];
            [self.imService.imStorage.conversationDao update:self.conversation];
            self.remindMessageArray = [[NSMutableArray alloc] initWithObjects:remindAttentionMessage, nil];
        }
    }
}
@end
