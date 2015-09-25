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
#import "MessageListViewController.h"
#import <BJHL-IM-iOS-SDK/BJIMStorage.h>
#import "NSString+MD5Addition.h"

@interface BJIMViewController ()
@property (nonatomic, strong) UITextField *userIdText;
@property (nonatomic, strong) UITextField *passwordText;
@property (nonatomic, strong) UITextField  *userNameText;


@end


#define APP_KEY  @"Fohqu0bo"


@implementation BJIMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.userIdText = [[UITextField alloc] initWithFrame:CGRectMake(50, 60, 200, 45) ];

    [self.userIdText setBackgroundColor:[UIColor grayColor]];
    self.userIdText.text = @"15011239890";
    [self.view addSubview:self.userIdText];
    self.userIdText.placeholder = @"老师端账号";
    
    self.userNameText = [[UITextField alloc] initWithFrame:CGRectMake(50, 120, 200, 45)];
    self.userNameText.text = @"测试";
    [self.view addSubview:self.userNameText];
    self.userNameText.placeholder = @"userNameText";
    
    self.passwordText = [[UITextField alloc] initWithFrame:CGRectMake(50, 165, 200, 45) ];
    
    [self.passwordText setBackgroundColor:[UIColor grayColor]];
    self.passwordText.text = @"dd111111";
    [self.view addSubview:self.passwordText];
    self.passwordText.placeholder = @"密码";
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 220, 200, 50)];
    [button setBackgroundColor:[UIColor grayColor]];
    [button setTitle:@"登录" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(loginClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
//    CGFloat val = 37.777779;
//    
//    CGFloat rounded_down = floorf(val * 100.0) / 100.0;   /* Result: 37.77 */
//    CGFloat nearest = floorf(val * 100 + 0.5) / 100.0;  /* Result: 37.78 */
//    CGFloat rounded_up = ceilf(val * 100) / 100.0;
//    double x = 88372.00699999;
//    double y = ceil(x * 1000)/1000.0;
}

- (void)loginClick:(id)sender {
    NSString *fullApi = @"http://test-appapi.genshuixue.com/auth/teacherLogin";
    NSString *authToken = @"GHsiZGV2aWNlX2lkIjoxNDk0NzYsInVzZXN1enFmIzsuMi0jYnFxYHV6cWYjOzItI2V2JDwzNjY1MzY5OjoyLiR1Y252JDwkW3treEZbbzwlgA";
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:fullApi method:kHttpMethod_POST];
    [requestParams appendPostParamValue:self.userIdText.text forKey:@"value"];
    [requestParams appendPostParamValue:self.passwordText.text forKey:@"password"];
    [requestParams appendPostParamValue:@"0" forKey:@"accept"];
    [requestParams appendPostParamValue:authToken forKey:@"auth_token"];
    
    NSString *timestamp = [NSString stringWithFormat:@"%lld", (long long)time(NULL)];
    NSString *signature = [self computeSignature:fullApi authToken:authToken timestamp:[timestamp UTF8String] appkey:APP_KEY];
    
    [requestParams appendPostParamValue:timestamp forKey:@"timestamp"];
    [requestParams appendPostParamValue:signature forKey:@"signature"];

    
    __WeakSelf__ weakSelf = self;
    [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSDictionary *result = response[@"result"];
        if ([[response valueForKey:@"code"] integerValue] == 1)
        {
            NSDictionary *person = result[@"person"];
            NSString *authToken = [result valueForKey:@"im_token"];
            [[BJIMManager shareInstance] loginWithOauthToken:authToken UserId:[[person objectForKey:@"id"] longLongValue]  userName:weakSelf.userNameText.text userAvatar:@"http://img.genshuixue.com/23.jpg" userRole:eUserRole_Teacher];
            
            MessageListViewController *conversatinList = [[MessageListViewController alloc] init];
            [weakSelf.navigationController pushViewController:conversatinList animated:YES];
        }
        
    } failure:^(NSError *error, RequestParams *params) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - API 
- (NSString *)computeSignature:(NSString *)fullApi
                     authToken:(NSString *)authToken
                     timestamp:(const char *)timestamp
                        appkey:(NSString *)appkey
{
    
    char apiGroup[128] = {0};
    char apiName[64] = {0};
    const char *_fullapi = [fullApi UTF8String];
    
    char *protocal_index = strstr(_fullapi, "://");
    protocal_index += 3;
    
    char *path_index = strstr(protocal_index, "/");
    if (path_index == NULL)
        return @"";
    
    char *path_end = strstr(_fullapi, "?");
    if (path_end == NULL)
    {
        path_end = (char *)_fullapi;
        path_end += strlen(_fullapi);
    }
    
    while (path_index < path_end) {
        char *next_index = strstr(path_index + 1, "/");
        if (next_index == NULL)
        {
            break;
        }
        
        strncat(apiGroup, path_index + 1, next_index - path_index - 1);
        path_index = next_index;
    }
    
    strncat(apiName, path_index + 1, path_end - path_index - 1);
    
    char temp[256] = {0};
    // authtoken apigroup apiname timestamp appkey
    sprintf(temp, "%s%s%s%s%s", [authToken UTF8String], apiGroup, apiName, timestamp, [appkey UTF8String]);
    
    //    char sign[64] = {0};
    //    md5_encode_str(sign, temp);
    NSString *sourceSignature = [NSString stringWithUTF8String:temp];
    return [sourceSignature stringFromMD5];
    
    //    return [NSString stringWithUTF8String:sign];
}

@end
