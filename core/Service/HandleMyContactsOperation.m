//
//  HandleMyContactsOperation.m
//  Pods
//
//  Created by 杨磊 on 15/7/25.
//
//


#import "HandleMyContactsOperation.h"

#import "BJIMService.h"
#import "MyContactsModel.h"
#import "IMEnvironment.h"


@implementation HandleMyContactsOperation

- (void)doOperationOnBackground
{
    
    User *user = [IMEnvironment shareInstance].owner;
    
    // clear my contacts
    [self.imService.imStorage deleteMyContactWithUser:user];

}

- (void)doAfterOperationOnMain
{

}

@end
