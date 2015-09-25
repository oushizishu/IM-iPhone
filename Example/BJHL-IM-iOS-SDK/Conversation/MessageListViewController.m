//
//  MessageListViewController.m
//  BJEducation_Institution
//
//  Created by Randy on 15/3/23.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import "MessageListViewController.h"
#import "MessageListTableViewCell.h"
//IM相关
#import <BJIMManager.h>
#import <Conversation.h>
#import <IMMessage.h>
#import <Conversation+DB.h>
#import <IMMessage+DB.h>

//Iphone-kit相关
#import "IMMessage+ViewModel.h"
#import "BJChatInfo.h"
#import "Conversation+ViewModel.h"
#import "User+ViewModel.h"

#import "GroupChatViewController.h"
#import "SingleChatViewController.h"

@interface MessageListViewController ()<IMConversationChangedDelegate>
@property (strong, nonatomic) NSMutableArray *sortConversations;
@property (strong, nonatomic) NSIndexPath *selectIndexPath;

@end

@implementation MessageListViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) awakeFromNib
{
    [[BJIMManager shareInstance] addConversationChangedDelegate:self];
}

-(instancetype) init
{
    self = [super init];
    if (self) {
        [[BJIMManager shareInstance] addConversationChangedDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[MessageListTableViewCell class] forCellReuseIdentifier:@"MessageListTableViewCell"];
    self.tableView.separatorColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"MessageListTableViewCell" bundle:nil] forCellReuseIdentifier:@"MessageListTableViewCell"];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"会话";
//    self.navigationItem.titleView = [self segmentCtrl];
}

- (BOOL)hidesBottomBarWhenPushed
{
    return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.selectIndexPath = nil;
    [self reloadConversation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - 方法

- (void)reloadConversation
{
    NSMutableArray *list = [[BJIMManager shareInstance].getAllConversation mutableCopy];
    [self.sortConversations removeAllObjects];
    [self.sortConversations addObjectsFromArray:list];
    [self.tableView reloadData];
}

- (void)sortContactListWithList:(NSMutableArray *)list
{
    [list sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Conversation *conv1 = obj1;
        Conversation *conv2 = obj2;
        IMMessage *message1 = conv1.lastMessage;
        IMMessage *message2 = conv2.lastMessage;
        
        //系统消息排第一位
        
        if ([conv1 getContactType] == BJContact_Admin)
        {
            return NSOrderedAscending;
        }
        else if([conv2 getContactType] == BJContact_Admin)
        {
            return NSOrderedDescending;
        }

        if ([conv1 getContactType] == BJContact_KeFu)
        {
            return NSOrderedAscending;
        }
        else if ([conv2 getContactType] == BJContact_KeFu)
        {
            return NSOrderedDescending;
        }
        
        if(message1.createAt > message2.createAt) {
            return NSOrderedAscending;
        }else {
            return NSOrderedDescending;
        }
    }];
}


#pragma mark - IMConversationChangedDelegate
- (void)didConversationDidChanged;
{
    [self reloadConversation];
//    [self updateMainMessageUnreadNum];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if ([self.sortConversations count] > 0){
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    } else {
        self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
        UILabel *lb = [[UILabel alloc] init];
        lb.text = @"无会话";
        lb.textColor = [UIColor blackColor];
        lb.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = lb;
    }
    
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.sortConversations count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    Conversation *contactInfo = [self.sortConversations objectAtIndex:indexPath.row];
    
    if ([contactInfo getContactType] == BJContact_KeFu || [contactInfo getContactType] == BJContact_Admin) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Perform the real delete action here. Note: you may need to check editing style
    //   if you do not perform delete only.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        Conversation *contactInfo = [self.sortConversations objectAtIndex:indexPath.row];
        
        // Delete the row from the data source
        [contactInfo resetUnReadNum];
        if ([[BJIMManager shareInstance] deleteConversation:contactInfo]) {
            [self.sortConversations removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        }
        
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageListTableViewCell" forIndexPath:indexPath];
    Conversation *conv = [self.sortConversations objectAtIndex:indexPath.row];
    
    {
        NSString *numStr = nil;
        NSInteger num = conv.unReadNum;
        if (num>=100)
            numStr = @"99+";
        else if (num>0)
            numStr = [NSString stringWithFormat:@"%ld",(long)num];
        [cell setBadgeNumber:numStr];
        cell.lastMessageLabel.attributedText = conv.getContactContentAttr;
        long long contactTime = conv.getContactTime;
        if (0!= contactTime) {
            cell.timeLabel.text = @"121212";
        }
        else {
            cell.timeLabel.text = @"";//[TimeUtils getSimpleTimeString:conv.getContactTime];
        }
    }
   
    if (conv.toRole == eUserRole_System) {
        cell.photoImageView.image = [UIImage imageNamed:@"ic_secretary"];
    }
    else if (conv.toRole == eUserRole_Kefu){
        cell.photoImageView.image = [UIImage imageNamed:@"ic_square_service"];
    }
    else
    {
//        [cell.photoImageView sd_setImageWithURL:[NSURL URLWithString:conv.getContactAvatar] placeholderImage:[UIImage imageNamed:@"ic_sm_user_default.png"]];
    }
    cell.nameLabel.text = conv.getContactName;
 
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"MessageListViewController didSelectRowAtIndexPath row:%ld,begin", (long)indexPath.row);
    if (self.selectIndexPath == nil) {
        self.selectIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        Conversation *conv = [self.sortConversations objectAtIndex:indexPath.row];
        if (conv.chat_t == eChatType_Chat) {
            SingleChatViewController *vc = [[SingleChatViewController alloc] initWithContactId:conv.toId contactRole:(BJContactType)conv.toRole];
            [self.navigationController pushViewController:vc animated:YES];
//            [VCManager showSingleChatViewWithUserId:conv.toId userRole:(BJContactType)conv.toRole navi:self.navigationController];
        }
        else
        {
            GroupChatViewController *vc = [[GroupChatViewController alloc] initWithContactId:conv.toId contactRole:BJContact_Group];
            [self.navigationController pushViewController:vc animated:YES];
//            [VCManager showGroupChatViewWithChatId:conv.toId navi:self.navigationController];
        }
    }
    NSLog(@"MessageListViewController didSelectRowAtIndexPath row:%ld,end", (long)indexPath.row);
}

#pragma mark - set get
- (NSMutableArray *)sortConversations
{
    if (_sortConversations == nil) {
        _sortConversations = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _sortConversations;
}
@end
