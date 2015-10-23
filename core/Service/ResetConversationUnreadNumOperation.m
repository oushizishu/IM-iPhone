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
    NSInteger otherUnReadNum;
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
        
        User *owner = [self.imService getUser:self.conversation.ownerId role:self.conversation.ownerRole];
        
        otherUnReadNum = [self.imService.imStorage.conversationDao sumOfAllUnReadNumBeenHiden:owner];
    }
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyConversationChanged];
    
    if (unReadNum > 0) {
        [self.imService notifyUnReadNumChanged:allUnReadNum other:otherUnReadNum];
    }
}

@end
