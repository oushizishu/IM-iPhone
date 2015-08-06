//
//  StoreRecentContactsOperation.m
//  Pods
//
//  Created by 杨磊 on 15/8/3.
//
//

#import "StoreRecentContactsOperation.h"
#import "BJIMService.h"
#import "User.h"
#import "IMEnvironment.h"
#import "RecentContactModel.h"
#import "RecentContacts.h"

@implementation StoreRecentContactsOperation

- (void)doOperationOnBackground
{
    
    User *owner = [IMEnvironment shareInstance].owner;;
    [self.imService.imStorage clearRecentContactsOwner:owner];

    for (NSInteger index = 0; index < [self.users count]; ++ index) {
        RecentContactModel *model = [self.users objectAtIndex:index];
        User *user = [[User alloc] init];
        user.userId = model.userId;
        user.userRole = model.userRole;
        user.name = model.name;
        user.avatar = model.avatar;
        user.nameHeader = model.nameHeader;
        [self.imService.imStorage insertOrUpdateUser:user];
        
        RecentContacts *contact = [[RecentContacts alloc] init];
        contact.userId = owner.userId;
        contact.userRole = owner.userRole;
        contact.contactId = model.userId;
        contact.contactRole = model.userRole;
        contact.remarkHeader = model.remarkHeader;
        contact.remarkName = model.remarkName;
        contact.updateTime = model.updateTime;
        
        [self.imService.imStorage insertRecentContact:user];
    }
    
    [super doOperationOnBackground];
    
}

- (void)doAfterOperationOnMain
{
    [super doAfterOperationOnMain];
}

@end
