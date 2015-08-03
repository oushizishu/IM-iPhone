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

@implementation StoreRecentContactsOperation

- (void)doOperationOnBackground
{
    
    User *owner = [IMEnvironment shareInstance].owner;;

    for (NSInteger index = 0; index < [self.users count]; ++ index) {
        User *user = [self.users objectAtIndex:index];
        
        [self.imService.imStorage insertRecentContact:user owner:owner];
    }
}

- (void)doAfterOperationOnMain
{
//    [self.imService getRecentContactsWithUser:[IMEnvironment shareInstance].owner];
}

@end
