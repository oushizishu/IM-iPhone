//
//  BJIMUrlSchema.m
//  Pods
//
//  Created by 杨磊 on 15/10/26.
//
//

#import "BJIMUrlSchema.h"
#import <BJAction.h>
#import "BJIMManager.h"

#define HERMES_ACTION_ADD_ATTENTION         @"addAttention"
#define HERMES_ACTION_REMOVE_BLACK          @"removeBlack"

@interface BJIMUrlSchema()
@property (nonatomic, strong) BJAction *actionManager;

@end

@implementation BJIMUrlSchema

+ (instancetype)shareInstance
{
    static dispatch_once_t token;
    static BJIMUrlSchema *instance;
    dispatch_once(&token, ^{
        instance = [[BJIMUrlSchema alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.actionManager = [[BJAction alloc] init];
        //hermes://o.c?a=xxx
        [self.actionManager setScheme:@"hermes"];
        [self.actionManager setHost:@"o.c"];
        [self.actionManager setActionKey:@"a"];
        
        [self addURLSchema];
    }
    return self;
}

- (void)handleUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    [self.actionManager sendTotarget:nil handleWithUrl:url];
}

- (void)addURLSchema
{
    // 关注
    [self.actionManager on:HERMES_ACTION_ADD_ATTENTION perform:^(id target, NSDictionary *payload) {
        
        [[BJIMManager shareInstance] addAttention:[[payload objectForKey:@"userNumber"] integerValue] role:[[payload objectForKey:@"userRole"] integerValue] callback:^(NSError *error ,BaseResponse *result){
            
            if(result.code == 0)
            {
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:nil message:@"关注成功!" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                [alter show];
            }else
            {
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:nil message:@"关注失败!" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                
                [alter show];
            }
                
        }];
    }];
    
    // 点击跳转到黑名单列表, 发送广播，外部处理
    [self.actionManager on:HERMES_ACTION_REMOVE_BLACK perform:^(id target, NSDictionary *payload) {
        [[BJIMManager shareInstance] cancelBlacklist:[[payload objectForKey:@"userNumber"] integerValue] role:[[payload objectForKey:@"userRole"] integerValue] callback:^(NSError *error ,BaseResponse *result){
            
            if(result.code == 0)
            {
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:nil message:@"移除黑名单成功!" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            
                [alter show];
            }else
            {
                UIAlertView *alter = [[UIAlertView alloc] initWithTitle:nil message:@"移除黑名单失败!" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                
                [alter show];
            }
        }];
    }];
    
}

@end
