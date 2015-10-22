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

@interface ResetConversationUnreadNumOperation()
{
    NSInteger unReadNum ;
    NSInteger allUnReadNum;
}

@end

@implementation ResetConversationUnreadNumOperation

- (void)doOperationOnBackground
{
    unReadNum = self.conversation.unReadNum;
    self.conversation.unReadNum = 0;
    [self.imService.imStorage.conversationDao update:self.conversation];
    
    if (unReadNum > 0) {
        allUnReadNum = [self.imService.imStorage sumOfAllConversationUnReadNumOwnerId:self.conversation.ownerId userRole:self.conversation.ownerRole];
    }
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyConversationChanged];
    
    if (unReadNum > 0) {
        [self.imService notifyUnReadNumChanged:allUnReadNum];
    }
}

@end
