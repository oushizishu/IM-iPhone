//
//  HandleDisbandGroupOperation.m
//  Pods
//
//  Created by 杨磊 on 15/8/14.
//
//

#import "HandleDisbandGroupOperation.h"
#import "BJIMService.h"
#import "Conversation.h"
#import "IMEnvironment.h"
#import "BJIMService+GroupManager.h"

@interface HandleDisbandGroupOperation()

@property (nonatomic, assign) BOOL hasConversationChanged;
@property (nonatomic, assign) BOOL hasContactsChanged;


@end

@implementation HandleDisbandGroupOperation

//2.服务器成功后本地会话删除 通知上层会话更新。 deleteConversation
//3.服务器成功后删除group所有成员关系、删除消息，并且删除group 通知上层联系人列表更新。 调用
//5.通知解散成功
- (void)doOperationOnBackground
{
    User *owner = [IMEnvironment shareInstance].owner;
    Conversation *conversation = [self.imService getConversationUserOrGroupId:self.groupId userRole:eUserRole_Anonymous ownerId:owner.userId ownerRole:owner.userRole chat_t:eChatType_GroupChat];
    if (conversation)
    {
        [self.imService deleteConversation:conversation owner:owner];
        _hasConversationChanged = YES;
    }
    
    _hasConversationChanged = [self.imService.imStorage deleteGroup:self.groupId];
}

- (void)doAfterOperationOnMain
{
    if (_hasConversationChanged) {
        [self.imService notifyConversationChanged];
    }
    
    if (_hasContactsChanged) {
        [self.imService notifyContactChanged];
    }
    
    [self.imService notifyDisbandGroup:self.groupId error:nil];
}


@end
