//
//  HandleCmdMessageOperation.m
//  Pods
//
//  Created by 杨磊 on 15/11/3.
//
//

#import "HandleCmdMessageOperation.h"
#import "IMEnvironment.h"
#import "NSString+Json.h"
#import "NSDictionary+Json.h"

#define ACTION_CMD_CONTACT_INFO_CHANGE  @"contact_info_change"
#define ACTION_CMD_NEW_GROUP_NOTICE     @"new_group_notice"
#define ACTION_CMD_UPDATE_CONTACT       @"update_contact"

@interface HandleCmdMessageOperation()

@property (nonatomic) SEL resultSelector;
@end

@implementation HandleCmdMessageOperation


- (void)doOperationOnBackground
{
   IMCmdMessageBody *messageBody = (IMCmdMessageBody *)self.message.messageBody;
    NSDictionary *dic = messageBody.payload;
    NSString *action  = dic[@"action"];
    
    if ([action isEqualToString:ACTION_CMD_CONTACT_INFO_CHANGE]) {
        self.resultSelector = [self dealContactInfoChange:messageBody service:self.imService];
    }else if ([action isEqualToString:ACTION_CMD_NEW_GROUP_NOTICE]) {
        self.resultSelector = [self dealNewGRoupNotice:messageBody service:self.imService];
    }else if ([action isEqualToString:ACTION_CMD_UPDATE_CONTACT])
    {
        self.resultSelector = [self dealUpdateContact:messageBody service:self.imService];
    }
    
}

- (void)doAfterOperationOnMain
{
    if (self.resultSelector && [self.imService respondsToSelector:self.resultSelector]) {
        [self.imService performSelector:self.resultSelector];
    }
}

- (SEL)dealContactInfoChange:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSError *error;
    User *user = [MTLJSONAdapter modelOfClass:[User class] fromJSONDictionary:[messageBody.payload[@"user"] jsonValue] error:&error];
    User *owner = [IMEnvironment shareInstance].owner;
    [imService.imStorage.userDao insertOrUpdateUser:user];
    
    return @selector(notifyContactChanged);
}

- (SEL)dealNewGRoupNotice:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    NSMutableDictionary *notice = [[NSMutableDictionary alloc] initWithDictionary:[messageBody.payload[@"notice"] jsonValue]];
    
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    
    User *owner = [IMEnvironment shareInstance].owner;
    int64_t groupId = [[notice objectForKey:@"group_id"] longLongValue];
    NSString *objectkey = [NSString stringWithFormat:@"UserId_%lld_userRole_%ld_NewGroupNotice_%lld",owner.userId,owner.userRole,groupId];
    
    BOOL ifNotify = YES;
    
    if ([notice objectForKey:@"content"] != nil && [[notice objectForKey:@"content"] length] > 0) {
        NSDictionary *oldNotice = [[userDefaultes objectForKey:objectkey] jsonValue];
        if (oldNotice != nil) {
            if ([[oldNotice objectForKey:@"id"] longLongValue]>=[[notice objectForKey:@"id"] longLongValue]) {
                ifNotify = NO;
                [notice setObject:@"NO" forKey:@"ifAutoShow"];
            }else
            {
                [notice setObject:@"YES" forKey:@"ifAutoShow"];
            }
        }else
        {
            [notice setObject:@"YES" forKey:@"ifAutoShow"];
        }
        
        [userDefaultes setObject:[notice jsonString] forKey:objectkey];
    }else
    {
        ifNotify = NO;
        [userDefaultes removeObjectForKey:objectkey];
    }
    
    [userDefaultes synchronize];
    
    if(ifNotify)
    {
        return @selector(notifyNewGroupNotice);
    }else
    {
        return nil;
    }

    
}

- (SEL)dealUpdateContact:(IMCmdMessageBody *)messageBody service:(BJIMService *)imService
{
    [imService.imEngine syncContacts];
    return nil;
}


@end
