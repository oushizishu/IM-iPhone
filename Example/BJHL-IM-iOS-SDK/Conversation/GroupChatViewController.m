//
//  GroupChatViewController.m
//  BJEducation_Institution
//
//  Created by Randy on 15/4/1.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import "GroupChatViewController.h"
#import <BJIMManager.h>
@interface GroupChatViewController ()<IMGroupProfileChangedDelegate>

@end

@implementation GroupChatViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    [[BJIMManager shareInstance] addGroupProfileChangedDelegate:self];
    
    [self createChatViewController];
    [self updateContent];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    }

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showGroupSettings
{
    [self.view endEditing:YES];
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.chatViewController;
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

#pragma mark - 环信聊天相关
- (void)createChatViewController
{
    if (self.chatViewController == nil){
        self.chatViewController = [[BJChatViewController alloc] initWithChatInfo:self.contact];
        
        [self addChildViewController:self.chatViewController];
        [self.view addSubview:self.chatViewController.view];
        [self.chatViewController didMoveToParentViewController:self];
        self.view.autoresizesSubviews = NO;
        self.chatViewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
    }
}

- (void)didGroupProfileChanged:(Group *)group;
{
    [self updateContent];
}

@end
