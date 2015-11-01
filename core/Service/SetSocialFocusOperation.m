//
//  SetSocialFocusOperation.m
//  Pods
//
//  Created by 杨磊 on 15/10/21.
//
//

#import "SetSocialFocusOperation.h"
#import "BJIMStorage.h"

@implementation SetSocialFocusOperation

- (void)doOperationOnBackground
{
    [self.imService.imStorage.socialContactsDao setContactFocusType:self.bAddFocus contact:self.contact owner:self.owner];
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyConversationChanged];
    [self.imService notifyUserInfoChanged:self.contact];
}

@end
