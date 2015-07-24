//
//  BJIMViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by YangLei-bjhl on 05/13/2015.
//  Copyright (c) 2014 YangLei-bjhl. All rights reserved.
//

#import "BJIMViewController.h"
#import <BJHL-Common-iOS-SDK/BJCommonProxy.h>
#import <BJHL-IM-iOS-SDK/BJIMManager.h>
#import "BJConversationListViewController.h"
#import <BJHL-IM-iOS-SDK/BJIMStorage.h>
@interface BJIMViewController ()
@property (nonatomic, strong) UITextField *userIdText;
@property (nonatomic, strong) UITextField  *userNameText;


@end

@implementation BJIMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.userIdText = [[UITextField alloc] initWithFrame:CGRectMake(50, 60, 200, 50) ];

    [self.userIdText setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:self.userIdText];
    self.userIdText.placeholder = @"userIdText";
    
    self.userNameText = [[UITextField alloc] initWithFrame:CGRectMake(50, 130, 200, 50)];

    [self.view addSubview:self.userNameText];
    self.userNameText.placeholder = @"userNameText";
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 220, 200, 50)];
    [button setBackgroundColor:[UIColor grayColor]];
    [button setTitle:@"登录" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(loginClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)loginClick:(id)sender {
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:@"http://hermes.genshuixue.com/hermes/getImToken" method:kHttpMethod_POST];
    [requestParams appendPostParamValue:self.userIdText.text forKey:@"user_number"];
    [requestParams appendPostParamValue:@"0" forKey:@"user_role"];
    
    __WeakSelf__ weakSelf = self;
    [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSString *authToken = [[response objectForKey:@"data"] valueForKey:@"im_token"];
        [[BJIMManager shareInstance] loginWithOauthToken:authToken UserId:[weakSelf.userIdText.text longLongValue]  userName:weakSelf.userNameText.text userAvatar:@"http://img.genshuixue.com/23.jpg" userRole:eUserRole_Teacher];
        
        BJConversationListViewController *conversatinList = [[BJConversationListViewController alloc] init];
        [weakSelf.navigationController pushViewController:conversatinList animated:YES];
        
    } failure:^(NSError *error, RequestParams *params) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
