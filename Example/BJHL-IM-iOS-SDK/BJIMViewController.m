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
#import "ConversationListViewController.h"
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
    
    static BJIMStorage * storage;
    if (!storage) {
        storage = [[BJIMStorage alloc]init];
    }
    /*
     
     @interface ConversationModel : MTLModel<MTLJSONSerializing>
     
     @property (nonatomic, assign) int64_t ownerId;
     @property (nonatomic, assign) IMUserRole ownerRole;
     @property (nonatomic, assign) int64_t toId;
     @property (nonatomic, assign) IMUserRole toRole;
     @property (nonatomic, assign) int64_t lastMsgRowId;
     @property (nonatomic, assign) IMChatType chat_t;
     @property (nonatomic, assign) NSInteger unReadNum;
     @end
     */
    /*
     Conversation *model = [[Conversation alloc]init];
     model.ownerId  = 100;
     model.ownerRole  = 100;
     model.toId  = 100;
     model.toRole  = 100;
     model.lastMsgRowId  = 100;
     model.chat_t  = 100;
     model.unReadNum  = 100;
     [storage insertConversation:model];
     */
    /*
     @property (nonatomic, assign) int16_t userId;
     @property (nonatomic, strong) NSString *name;
     @property (nonatomic, strong) NSString *avatar;
     @property (nonatomic, assign) IMUserRole userRole;
     
     */
/*
    static BJIMStorage * storage;
    if (!storage) {
        storage = [[BJIMStorage alloc]init];
    }
    User *user = [User new];
    user.userId = 100;
    user.name   = @"hha";
    user.avatar = @"baidu.com";
    user.userRole = 100;
    [storage insertOrUpdateUser:user];
 */
    
    /*
     @property (nonatomic, assign) int64_t groupId ;
     @property (nonatomic, copy) NSString *groupName;
     @property (nonatomic, copy) NSString *avatar;
     @property (nonatomic, copy) NSString *descript;
     @property (nonatomic, assign) NSInteger isPublic;
     @property (nonatomic, assign) NSInteger maxusers;
     @property (nonatomic, assign) NSInteger approval;
     @property (nonatomic, assign) int64_t ownerId;
     @property (nonatomic, assign) IMUserRole ownerRole;
     @property (nonatomic, assign) NSInteger memberCount;
     @property (nonatomic, assign) NSInteger status; // 0 保留 1 开发 2删除
     @property (nonatomic, assign) int64_t createTime;
     
     @property (nonatomic, assign) int64_t lastMessageId;
     @property (nonatomic, assign) int64_t startMessageId;
     @property (nonatomic, assign) int64_t endMessageId;
     */
    Group *group = [Group new];
    group.groupId = 100;
    group.groupName = @"100";
    group.avatar = @"100";
    group.descript = @"100";
    group.isPublic = 100;
    group.maxusers = 100;
    group.approval = 100;
    group.ownerId = 100;
    group.ownerRole = 100;
    group.memberCount = 100;
    group.status = 100;
    group.createTime = 100;
    group.lastMessageId = 100;
    group.startMessageId = 100;
    group.endMessageId   = 100;
    [storage insertOrUpdateGroup:group];    
}

- (void)loginClick:(id)sender {
    RequestParams *requestParams = [[RequestParams alloc] initWithUrl:@"http://hermes.genshuixue.com/hermes/getImToken" method:kHttpMethod_POST];
    [requestParams appendPostParamValue:self.userIdText.text forKey:@"user_number"];
    [requestParams appendPostParamValue:@"0" forKey:@"user_role"];
    
    __WeakSelf__ weakSelf = self;
    [BJCommonProxyInstance.networkUtil doNetworkRequest:requestParams success:^(id response, NSDictionary *responseHeaders, RequestParams *params) {
        NSString *authToken = [[response objectForKey:@"data"] valueForKey:@"im_token"];
        [[BJIMManager shareInstance] loginWithOauthToken:authToken UserId:[weakSelf.userIdText.text longLongValue]  userName:weakSelf.userNameText.text userAvatar:@"http://img.genshuixue.com/23.jpg" userRole:eUserRole_Teacher];
        
        ConversationListViewController *conversatinList = [[ConversationListViewController alloc] init];
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
