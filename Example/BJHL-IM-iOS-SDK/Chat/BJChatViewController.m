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

#import "BJChatInputBarViewController.h"
#import "BJSendMessageHelper.h"
#import "BJChatAudioPlayerHelper.h"
#import "IMMessage+ViewModel.h"

@interface BJChatViewController ()<UITableViewDataSource,UITableViewDelegate, IMReceiveNewMessageDelegate, IMLoadMessageDelegate,BJChatInputProtocol,BJSendMessageProtocol>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *messageList;
@property (strong, nonatomic) BJChatInfo *chatInfo;
@property (strong, nonatomic) Conversation *conversation;

@property (strong, nonatomic) NSMutableDictionary *messageHeightDic;

/**
 *  输入区域的控制
 */
@property (strong, nonatomic) BJChatInputBarViewController *inputController;

@property (nonatomic) BOOL isScrollToBottom;
@end

@implementation BJChatViewController

- (void)dealloc
{
    [self.view removeObserver:self forKeyPath:@"frame"];
    [BJSendMessageHelper sharedInstance].deledate = nil;
}

- (instancetype)initWithChatInfo:(BJChatInfo *)chatInfo;
{
    self = [super init];
    if (self) {
        _chatInfo = chatInfo;
        _isScrollToBottom = YES;
        [BJSendMessageHelper sharedInstance].deledate = self;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.chatInfo.chat_t == eChatType_GroupChat) {
        [[BJIMManager shareInstance] startChatToGroup:self.chatInfo.getToId];
    }
    else
    {
        [[BJIMManager shareInstance] startChatToUserId:self.chatInfo.getToId role:self.chatInfo.getToRole];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isScrollToBottom) {
        [self scrollViewToBottom:YES];

    }
    else{
        self.isScrollToBottom = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[BJIMManager shareInstance] stopChat];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isScrollToBottom = YES;
    
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        [self setAutomaticallyAdjustsScrollViewInsets:NO];
    }
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [[BJIMManager shareInstance] addReceiveNewMessageDelegate:self];
    [[BJIMManager shareInstance] addLoadMoreMessagesDelegate:self];
    
    NSArray *array = [[BJIMManager shareInstance] loadMessageFromMinMsgId:0 inConversation:self.conversation];
    self.messageList = [[NSMutableArray alloc] initWithArray:array];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.inputController.view];
    [self addChildViewController:self.inputController];
    [self.inputController didMoveToParentViewController:self];
    [self updateSubViewFrame];
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyBoardHidden)];
    [self.tableView addGestureRecognizer:tap];
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

#pragma mark - 消息操作方法
- (void)addNewMessages:(NSArray *)messages isForward:(BOOL)forward;
{
    if (messages.count <= 0) {
        return;
    }
    
    @TODO("添加时间显示");
    if (forward) {
        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, messages.count)];
        [self.messageList insertObjects:messages atIndexes:set];
        [self.tableView reloadData];
    }
    else
    {
        [self.messageList addObjectsFromArray:messages];
        BOOL should = [self analyzeScrollViewShouldToBottom];
        [self.tableView reloadData];
        if (should) {
            [self scrollViewToBottom:YES];
        }
    }

}

#pragma mark - observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateSubViewFrame];
}

#pragma mark - 视图更新
- (void)updateSubViewFrame
{
    CGRect rect = self.inputController.view.frame;
    rect.origin.y = self.view.bounds.size.height - rect.size.height;
    self.inputController.view.frame = rect;
    
    rect = self.view.bounds;
    rect.size.height -= self.inputController.view.frame.size.height;
    self.tableView.frame = rect;
}

/**
 *  分析是否要滑动到最下面规则 如果偏移量距下不超过15，则 YES
 *
 *  @return
 */
- (BOOL)analyzeScrollViewShouldToBottom
{
    CGFloat canOffsetY = self.tableView.contentSize.height - self.tableView.frame.size.height + self.tableView.contentInset.bottom + self.tableView.contentInset.top;
    if (canOffsetY>0)
    {
        if (self.tableView.contentOffset.y > canOffsetY-15) {
            return YES;
        }
        else
            return NO;
    }
    return NO;
}

- (void)scrollViewToBottom:(BOOL)animated
{
    CGFloat canOffsetY = self.tableView.contentSize.height - self.tableView.frame.size.height + self.tableView.contentInset.bottom + self.tableView.contentInset.top;

    if (canOffsetY>0)
    {
        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height + self.tableView.contentInset.bottom);
        [self.tableView setContentOffset:offset animated:animated];
        
    }
}

- (void)reloadWithMessage:(IMMessage *)message
{
    NSInteger index = [self.messageList indexOfObject:message];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)showBigImageWithMessage:(IMMessage *)message
{
    @TODO("显示大图");
}

- (void)audioCellTapWithMessage:(IMMessage *)message
{
    __weak typeof(self) weakSelf = self;
    if (message.isPlaying) {
        [[BJChatAudioPlayerHelper sharedInstance] stopPlayerWithMessage:message];
    }
    else
    {
        [[BJChatAudioPlayerHelper sharedInstance] startPlayerWithMessage:message callback:^(NSError *error) {
            @TODO("提示错误消息");
            [weakSelf.tableView reloadData];
        }];
    }
    [self.tableView reloadData];
}

#pragma mark - 键盘相关

// 点击背景隐藏
-(void)keyBoardHidden
{
    [self.inputController endEditing:YES];
}

#pragma mark - message delegate

- (void)didReceiveNewMessages:(NSArray *)newMessages
{
    for (NSInteger index = 0; index < [newMessages count]; ++index)
    {
        IMMessage *msg = [newMessages objectAtIndex:index];
        if (msg.conversationId == self.conversation.rowid)
        {
            [self addNewMessages:@[msg] isForward:NO];
        }
    }
}

- (void)didLoadMessages:(NSArray *)messages conversation:(Conversation *)conversation hasMore:(BOOL)hasMore
{
    if (conversation.rowid == self.conversation.rowid) {
        [self addNewMessages:messages isForward:YES];
    }
}

- (void)willDeliveryMessage:(IMMessage *)message;
{
    [self reloadWithMessage:message];
}

- (void)didDeliveredMessage:(IMMessage *)message
                  errorCode:(NSInteger)errorCode
                      error:(NSString *)errorMessage;
{
    [self reloadWithMessage:message];
}

- (void)willSendMessage:(IMMessage *)message;
{
    [self addNewMessages:@[message] isForward:NO];
}

#pragma mark - BJChatInputProtocol
/**
 *  高度变到toHeight
 */
- (void)didChangeFrameToHeight:(CGFloat)toHeight;
{
    CGFloat offset = ceilf((toHeight-[BJChatInputBarViewController defaultHeight]));
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, offset, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, offset, 0);
    
    if(toHeight > [BJChatInputBarViewController defaultHeight]+10){
        [self scrollViewToBottom:NO];

    }
}

#pragma mark - UIResponder actions


- (void)routerEventWithName:(NSString *)eventName userInfo:(NSDictionary *)userInfo
{
    IMMessage *message = [userInfo objectForKey:kRouterEventUserInfoObject];
    if ([eventName isEqualToString:kRouterEventImageBubbleTapEventName]){
        [self showBigImageWithMessage:message];
    }
    else if ([eventName isEqualToString:kResendButtonTapEventName])
    {
        [[BJIMManager shareInstance] retryMessage:message];
    }
    else if ([eventName isEqualToString:kRouterEventChatCellBubbleTapEventName])
    {
        [self audioCellTapWithMessage:message];
    }
}

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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
- (Conversation *)conversation
{
    if (_conversation == nil) {
        if (self.chatInfo.chat_t == eChatType_GroupChat) {
            _conversation = [[BJIMManager shareInstance] getConversationGroupId:self.chatInfo.getToId];
        }
        else
        _conversation = [[BJIMManager shareInstance] getConversationUserId:self.chatInfo.getToId role:self.chatInfo.getToRole];
    }
    return _conversation;
}

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
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

- (BJChatInputBarViewController *)inputController
{
    if (_inputController == nil) {
        _inputController = [[BJChatInputBarViewController alloc] initWithChatInfo:self.chatInfo];
        _inputController.delegate = self;
    }
    return _inputController;
}

@end
