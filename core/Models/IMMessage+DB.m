//
//  IMMessage+DB.m
//  Pods
//
//  Created by 杨磊 on 15/7/24.
//
//

#import "IMMessage+DB.h"
#import "BJIMService.h"
#import <objc/runtime.h>

@implementation IMMessage(DB)

static char BJIMMessageIMService;
//static char BJIMMessageIMSenderUser;
//static char BJIMMessageIMReceiverUser;
//static char BJIMMessageIMReceiverGroup;

- (User *)getSenderUser
{
    return [self.imService getUser:self.sender role:self.senderRole];
}

- (User *)getReceiverUser
{
    return [self.imService getUser:self.receiver role:self.receiverRole];
    
}

- (Group *)getReceiverGroup
{
    return [self.imService getGroup:self.receiver];
}

- (void)setImService:(BJIMService *)imService
{
    objc_setAssociatedObject(self, &BJIMMessageIMService, imService, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BJIMService *)imService
{
    return objc_getAssociatedObject(self, &BJIMMessageIMService);
}

- (void)markRead
{
    if (self.read == 1) return;
    self.read = 1;
    [self.imService.imStorage.messageDao update:self];
}

- (void)markPlayed
{
    if (self.played == 1) return;
    self.played = 1;
    [self.imService.imStorage.messageDao update:self];
}

@end
