//
//  IMMessage+DB.m
//  Pods
//
//  Created by 杨磊 on 15/7/24.
//
//

#import "IMMessage+DB.h"
#import "BJIMService.h"

@implementation IMMessage(DB)

static char BJIMMessageIMService;
static char BJIMMessageIMSenderUser;
static char BJIMMessageIMReceiverUser;
static char BJIMMessageIMReceiverGroup;

- (User *)getSenderUser
{
    User * _sendUser = objc_getAssociatedObject(self, &BJIMMessageIMSenderUser);
    
    if (_sendUser != nil) return _sendUser;
    
    if (self.imService == nil) return nil;
    
    _sendUser = [self.imService getUser:self.sender role:self.senderRole];
    objc_setAssociatedObject(self, &BJIMMessageIMSenderUser, _sendUser, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return _sendUser;
}

- (User *)getReceiverUser
{
    if (self.chat_t == eChatType_GroupChat) return nil;
    
    User * _receiverUser = objc_getAssociatedObject(self, &BJIMMessageIMReceiverUser);
    
    if (_receiverUser != nil) return _receiverUser;
    
    if (self.imService == nil) return nil;
    
    _receiverUser = [self.imService getUser:self.receiver role:self.receiverRole];
    objc_setAssociatedObject(self, &BJIMMessageIMReceiverUser, _receiverUser, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return _receiverUser;
    
}

- (Group *)getReceiverGroup
{
    if (self.chat_t == eChatType_Chat) return nil;
    Group *_receiverGroup = objc_getAssociatedObject(self, &BJIMMessageIMReceiverGroup);
    
    if (_receiverGroup) return _receiverGroup;
    
    _receiverGroup = [self.imService getGroup:self.receiver];
    objc_setAssociatedObject(self, &BJIMMessageIMReceiverGroup, _receiverGroup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return _receiverGroup;
}

- (void)setImService:(BJIMService *)imService
{
    objc_setAssociatedObject(self, &BJIMMessageIMService, imService, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BJIMService *)imService
{
    return objc_getAssociatedObject(self, &BJIMMessageIMService);
}

@end
