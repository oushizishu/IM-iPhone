//
//  ChatBaseViewController.m
//  BJEducation_Institution
//
//  Created by Randy on 15/4/6.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import "ChatBaseViewController.h"
#import "BJIMKit.h"
@interface ChatBaseViewController ()

@end

@implementation ChatBaseViewController

- (instancetype)initWithContactId:(long long)userId contactRole:(BJContactType)type;
{
    self = [super init];
    if (self) {
        if (type != BJContact_Group) {
            User *user = [[BJIMManager shareInstance] getUser:userId role:(IMUserRole)type];
            _contact = [[BJChatInfo alloc] initWithUser:user];
        }
        else
        {
            Group *group = [[BJIMManager shareInstance] getGroup:userId];
            _contact = [[BJChatInfo alloc] initWithGroup:group];
        }
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
