//
//  ConversationListViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by 杨磊 on 15/7/16.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJConversationListViewController.h"
#import <BJHL-IM-iOS-SDK/BJIMManager.h>
#import "BJConversationTableViewCell.h"
#import "BJChatViewController.h"

@interface BJConversationListViewController()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *allConversations;

@end

@implementation BJConversationListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    self.allConversations = [[BJIMManager shareInstance] getAllConversation];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allConversations count];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identity = @"ConversationTableViewCell";
    
    BJConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil)
    {
        cell = [[BJConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
    }
    
    cell.conversation = [self.allConversations objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BJChatViewController *vc = [[BJChatViewController alloc] init];
}


@end
