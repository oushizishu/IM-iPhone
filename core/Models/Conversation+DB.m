//
//  Conversation+DB.m
//  Pods
//
//  Created by 杨磊 on 15/7/20.
//
//

#import "Conversation+DB.h"
#import "BJIMService.h"
#import "IMMessage+DB.h"
#import <objc/runtime.h>

@implementation Conversation(DB)

@dynamic imService;

//static char BJIMConversationChatToUser;
//static char BJIMConversationChatToGroup;
//static char BJIMConversationLastMessage;
static char BJIMConversationIMService;

- (User *)chatToUser
{
    if (self.chat_t == eChatType_GroupChat)
    {
        return nil;
    }
    
    return [self.imService getUser:self.toId role:self.toRole];
}

- (Group *)chatToGroup
{
    if (self.chat_t == eChatType_Chat)
    {
        return nil;
    }
    return [self.imService getGroup:self.toId];
}

- (IMMessage *)lastMessage
{
    IMMessage *msg = [self.imService.imStorage.messageDao loadWithMessageId:self.lastMessageId];
    msg.imService = self.imService;
    
    return msg;
}

- (void)setImService:(BJIMService *)imService
{
    objc_setAssociatedObject(self, &BJIMConversationIMService, imService, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BJIMService *)imService
{
    return objc_getAssociatedObject(self, &BJIMConversationIMService);
}

- (void)resetUnReadNum
{
    if (self.unReadNum == 0) return;
    
    [self.imService resetConversationUnreadnum:self];
}

@end
