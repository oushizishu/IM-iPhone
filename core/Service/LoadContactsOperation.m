//
//  LoadContactsOperation.m
//  Pods
//
//  Created by 杨磊 on 15/10/14.
//
//

#import "LoadContactsOperation.h"
#import "BJIMService.h"
#import "User.h"

@implementation LoadContactsOperation

- (void)doOperationOnBackground
{
    [self.imService getStudentContactsWithUser:self.owner];
    [self.imService getTeacherContactsWithUser:self.owner];
    [self.imService getInstitutionContactsWithUser:self.owner];
}

- (void)doAfterOperationOnMain
{
}

@end
