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

@implementation Conversation(DB)

@dynamic imService;

static char BJIMConversationChatToUser;
static char BJIMConversationChatToGroup;
static char BJIMConversationLastMessage;
static char BJIMConversationIMService;

- (User *)chatToUser
{
    if (self.chat_t == eChatType_GroupChat)
    {
        return nil;
    }
    
    User * _chatToUser = objc_getAssociatedObject(self, &BJIMConversationChatToUser);
    
    if (_chatToUser != nil) return _chatToUser;
    
    if (self.imService == nil) return nil;
    _chatToUser = [self.imService getUser:self.toId role:self.toRole];
    objc_setAssociatedObject(self, &BJIMConversationChatToUser, _chatToUser, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return _chatToUser;
}

- (Group *)chatToGroup
{
    if (self.chat_t == eChatType_Chat)
    {
        return nil;
    }
    Group *_chatToGroup = objc_getAssociatedObject(self, &BJIMConversationChatToGroup);
    if (_chatToGroup != nil) return _chatToGroup;
    
    if(self.imService == nil) return nil;
    _chatToGroup = [self.imService getGroup:self.toId];
    objc_setAssociatedObject(self, &BJIMConversationChatToGroup, _chatToGroup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return _chatToGroup;
}

//- (NSMutableArray *)messages
//{
//    NSMutableArray *_messages = objc_getAssociatedObject(self, &BJIMConversationMessages);
//    if (_messages == nil)
//    {
//        if (self.imService == nil) return nil;
//        
//        if (self.chat_t == eChatType_Chat)
//        {
//            NSArray *array = [self.imService.imStorage loadChatMessagesInConversation:self.rowid];
//            _messages = [NSMutableArray arrayWithArray:array];
//        }
//        else
//        {
//            Group *_chatToGroup = [self chatToGroup];
//            NSArray *array = [self.imService.imStorage loadGroupChatMessages:_chatToGroup inConversation:self.rowid];
//            _messages = [NSMutableArray arrayWithArray:array];
//        }
//        
//        objc_setAssociatedObject(self, &BJIMConversationMessages, _messages, OBJC_ASSOCIATION_RETAIN);
//    }
//    [_messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        IMMessage *msg = (IMMessage *)obj;
//        msg.imService = self.imService;
//    }];
//    return _messages;
//}

- (IMMessage *)lastMessage
{
    IMMessage *_lastMessage = objc_getAssociatedObject(self, &BJIMConversationLastMessage);
    if (_lastMessage != nil && self.lastMsgRowId == _lastMessage.rowid)
    {
        return _lastMessage;
    }
    
    if (self.imService == nil) return nil;
    
    _lastMessage = [self.imService.imStorage queryMessage:self.lastMsgRowId];
    objc_setAssociatedObject(self, &BJIMConversationLastMessage, _lastMessage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return _lastMessage;
}

- (void)setImService:(BJIMService *)imService
{
    objc_setAssociatedObject(self, &BJIMConversationIMService, imService, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BJIMService *)imService
{
    return objc_getAssociatedObject(self, &BJIMConversationIMService);
}
@end
