//
//  BJIMViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by YangLei-bjhl on 05/13/2015.
//  Copyright (c) 2014 YangLei-bjhl. All rights reserved.
//

#import "BJIMViewController.h"
#import <BJHL-Common-iOS-SDK/BJCommonProxy.h>


@interface BJIMViewController ()
@property (nonatomic, strong) UITextView *userIdText;
@property (nonatomic, strong) UITextView *userNameText;


@end

@implementation BJIMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.userIdText = [[UITextView alloc] initWithFrame:CGRectMake(50, 60, 200, 50) textContainer:nil];
    [self.userIdText setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:self.userIdText];
    
    self.userNameText = [[UITextView alloc] initWithFrame:CGRectMake(50, 130, 200, 50)];
    [self.userNameText setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:self.userNameText];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 220, 200, 50)];
    [button setBackgroundColor:[UIColor grayColor]];
    [button setTitle:@"登录" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(loginClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)loginClick:(id)sender {
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:@"http://hermes.genshuixue.com/hermes/getImToken" method:kHttpMethod_POST];
    [requestParams appendPostParamValue:self.userIdText.text forKey:@"user_id"];
    [requestParams appendPostParamValue:@"2" forKey:@"user_type"];
    [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        
    } failure:^(NSError *error, RequestParams *params) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end