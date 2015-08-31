//
//  ResetConversationUnreadNumOperation.m
//  Pods
//
//  Created by 杨磊 on 15/8/13.
//
//

#import "ResetConversationUnreadNumOperation.h"
#import "BJIMService.h"
#import "BJIMStorage.h"

@implementation ResetConversationUnreadNumOperation

- (void)doOperationOnBackground
{
    self.conversation.unReadNum = 0;
    [self.imService.imStorage.conversationDao update:self.conversation];
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyConversationChanged];
}

@end
