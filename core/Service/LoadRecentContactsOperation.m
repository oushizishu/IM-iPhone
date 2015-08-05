//
//  LoadRecentContactsOperation.m
//  Pods
//
//  Created by 杨磊 on 15/8/3.
//
//

#import "LoadRecentContactsOperation.h"
#import "BJIMService.h"
#import "IMEnvironment.h"

@interface LoadRecentContactsOperation()
@property (nonatomic, strong) NSArray *contacts;

@end

@implementation LoadRecentContactsOperation

- (void)doOperationOnBackground
{
    User *owner = [IMEnvironment shareInstance].owner;
    
    NSArray *list = [self.imService.imStorage queryRecentContactsWithUserId:owner.userId userRole:owner.userRole];
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger index = 0; index < [list count]; ++ index)
    {
        User *user = [list objectAtIndex:index];
        User *_user = [self.imService getUserFromCache:user.userId role:user.userRole];
        if (_user)
        {
            [_user mergeValuesForKeysFromModel:user];
            [array addObject:_user];
        }
        else
        {
            [self.imService insertUserToCache:user];
            [array addObject:user];
        }
    }
    
    self.contacts = array;
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyRecentContactsChanged:self.contacts];
}

@end
