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
    
}

@end
