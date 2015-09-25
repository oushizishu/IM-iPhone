//
//  SingleViewController.m
//  BJEducation_Institution
//
//  Created by Randy on 15/4/1.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import "SingleChatViewController.h"
#import "BJChatInfo.h"
#import <BJIMManager.h>
#import "User+ViewModel.h"
@interface SingleChatViewController ()<IMUserInfoChangedDelegate>
@end

@implementation SingleChatViewController

- (void)dealloc
{
    
}

- (instancetype)initWithContactId:(long long)userId contactRole:(BJContactType)type
{
    self = [super initWithContactId:userId contactRole:type];
    if (self) {

    }
    return self;
}

- (void)viewDidAppearFirstHandle
{

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.title = [self.contact getContactName];
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.chatViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    [self createChatViewController];
    [self updateContent];

    [[BJIMManager shareInstance] addUserInfoChangedDelegate:self];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation
 腾讯科技有限公司，环信聊天相关，我们得爱情，

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)updateContent
{
    self.title = [self.contact getContactName];
    

}

#pragma mark - 设置相关
- (void)showKefuSettings
{
    [self.view endEditing:YES];
}

- (void)showTeacherSettings
{
    [self.view endEditing:YES];
}

- (void)showStudentSettings
{
    [self.view endEditing:YES];
}

#pragma mark - 环信聊天相关
- (void)createChatViewController
{
    if (self.chatViewController == nil){
        self.chatViewController = [[BJChatViewController alloc] initWithChatInfo:self.contact];
        [self addChildViewController:self.chatViewController];
        [self.view addSubview:self.chatViewController.view];
        self.view.autoresizesSubviews = NO;
        self.chatViewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
        [self.chatViewController didMoveToParentViewController:self];
    }
}

- (void)didUserInfoChanged:(User *)user;
{
    self.title = [user getContactName];
}

@end
