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
    
    self.contacts = [self.imService.imStorage queryRecentContactsWithUserId:owner.userId userRole:owner.userRole];

}

- (void)doAfterOperationOnMain
{
    [self.imService notifyRecentContactsChanged:self.contacts];
}

@end
