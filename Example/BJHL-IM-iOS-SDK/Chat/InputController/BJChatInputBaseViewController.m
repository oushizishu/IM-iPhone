//
//  ChatInputBaseViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInputBaseViewController.h"
#import <BJIMManager.h>
#import <IMTxtMessageBody.h>
@interface BJChatInputBaseViewController ()

@end

@implementation BJChatInputBaseViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSAssert(0, @"不能使用此初始化方法");
    }
    return self;
}

- (instancetype)initWithChatInfo:(BJChatInfo *)chatInfo;

{
    self = [super init];
    if (self) {
        _chatInfo = chatInfo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



@end
