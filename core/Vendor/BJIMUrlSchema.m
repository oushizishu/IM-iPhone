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
#import "MBProgressHUD.h"

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
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].delegate window] animated:YES];
        
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.margin = 10.f;
        hud.yOffset = 150.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud show:YES];
        
        [[BJIMManager shareInstance] addAttention:[[payload objectForKey:@"userNumber"] integerValue] role:[[payload objectForKey:@"userRole"] integerValue] callback:^(NSError *error ,BaseResponse *result){
            
            hud.mode = MBProgressHUDModeText;
            
            if(result.code == 0)
            {
                hud.labelText = @"关注成功";
                [hud hide:YES afterDelay:1.0f];
            }else
            {
                hud.labelText = @"关注失败";
                [hud hide:YES afterDelay:1.0f];
            }
                
        }];
    }];
    
    // 点击调用取消黑名单接口
    [self.actionManager on:HERMES_ACTION_REMOVE_BLACK perform:^(id target, NSDictionary *payload) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].delegate window] animated:YES];
        
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.margin = 10.f;
        hud.yOffset = 150.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud show:YES];
        
        [[BJIMManager shareInstance] cancelBlacklist:[[payload objectForKey:@"userNumber"] integerValue] role:[[payload objectForKey:@"userRole"] integerValue] callback:^(NSError *error ,BaseResponse *result){
            
            hud.mode = MBProgressHUDModeText;
            
            if(result.code == 0)
            {
                hud.labelText = @"移除成功";
                [hud hide:YES afterDelay:1.0f];
            }else
            {
                hud.labelText = @"移除失败";
                [hud hide:YES afterDelay:1.0f];
            }
        }];
    }];
    
}

@end
