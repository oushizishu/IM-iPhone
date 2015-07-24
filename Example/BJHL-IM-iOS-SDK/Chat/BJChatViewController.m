//
//  ChatViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatViewController.h"
#import <IMMessage.h>
#import "BJChatCellFactory.h"
#import <BJHL-IM-iOS-SDK/BJIMManager.h>
#import <Conversation+DB.h>

@interface BJChatViewController ()<UITableViewDataSource,UITableViewDelegate, IMReceiveNewMessageDelegate, IMLoadMessageDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *messageList;
@property (strong, nonatomic) Conversation *conversation;

@property (strong, nonatomic) NSMutableDictionary *messageHeightDic;
@end

@implementation BJChatViewController

- (instancetype)initWithConversation:(Conversation *)conversation
{
    self = [super init];
    if (self) {
        _conversation = conversation;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[BJIMManager shareInstance] addReceiveNewMessageDelegate:self];
    [[BJIMManager shareInstance] addLoadMoreMessagesDelegate:self];
    NSArray *array = [[BJIMManager shareInstance] loadMessageFromMinMsgId:0 inConversation:self.conversation];
    self.messageList = [[NSMutableArray alloc] initWithArray:array];
    
    
    
    [self.view addSubview:self.tableView];

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

#pragma mark - UITableView delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messageList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMMessage *message = [self.messageList objectAtIndex:indexPath.row];
    UITableViewCell<BJChatViewCellProtocol> *cell = [tableView dequeueReusableCellWithIdentifier:[[BJChatCellFactory sharedInstance] cellIdentifierWithMessageType:message.msg_t]];
    if (cell == nil) {
        cell = [[BJChatCellFactory sharedInstance] cellWithMessageType:message.msg_t];
    }
    [cell setCellInfo:message indexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMMessage *message = [self.messageList objectAtIndex:indexPath.row];
    CGFloat Height = 0;
    if ([self.messageHeightDic objectForKey:@(message.msgId)]) {
        Height = [[self.messageHeightDic objectForKey:@(message.msgId)] floatValue];
    }
    else
    {
        Height = [[BJChatCellFactory sharedInstance] cellHeightWithMessage:message indexPath:indexPath];
        [self.messageHeightDic setObject:@(Height) forKeyedSubscript:@(message.msgId)];
    }
    return Height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}


#pragma mark - set get
- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray *)messageList
{
    if (_messageList == nil) {
        _messageList = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _messageList;
}

- (NSMutableDictionary *)messageHeightDic
{
    if (_messageHeightDic == nil) {
        _messageHeightDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return _messageHeightDic;
}

- (void)didReceiveNewMessages:(NSArray *)newMessages
{
    for (NSInteger index = 0; index < [newMessages count]; ++index)
    {
        IMMessage *msg = [newMessages objectAtIndex:index];
        if (msg.conversationId == self.conversation.rowid)
        {
            [self.messageList addObject:msg];
        }
    }
}

- (void)didLoadMessages:(NSArray *)messages conversation:(Conversation *)conversation hasMore:(BOOL)hasMore
{

}

@end
