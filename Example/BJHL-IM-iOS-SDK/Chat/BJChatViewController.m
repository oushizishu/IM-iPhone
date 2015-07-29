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
#import <BJIMManager.h>
#import <IMMessage+DB.h>

#import "BJChatTimeCell.h"

#import "SRRefreshView.h"

#import <NSDate+Category.h>

@interface BJChatViewController ()<UITableViewDataSource,UITableViewDelegate, IMReceiveNewMessageDelegate, IMLoadMessageDelegate,BJChatInputProtocol,BJSendMessageProtocol,IMDeliveredMessageDelegate>
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

@property (strong, nonatomic) SRRefreshView *slimeView;

@end

@implementation BJChatViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view removeObserver:self forKeyPath:@"frame"];
    [BJSendMessageHelper sharedInstance].deledate = nil;
    _slimeView.delegate = nil;
    _slimeView = nil;
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
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
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

    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isScrollToBottom = YES;
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroud) name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        [self setAutomaticallyAdjustsScrollViewInsets:NO];
    }
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [[BJIMManager shareInstance] addReceiveNewMessageDelegate:self];
    [[BJIMManager shareInstance] addLoadMoreMessagesDelegate:self];
    [[BJIMManager shareInstance] addDeliveryMessageDelegate:self];
    [self.conversation resetUnReadNum];
    
    NSArray *array = [[BJIMManager shareInstance] loadMessageFromMinMsgId:0 inConversation:self.conversation];
    [self addNewMessages:array isForward:NO];
    
    if ([array count] > 0 && self.conversation)
    {
        [[BJIMManager shareInstance] loadMessageFromMinMsgId:[[array objectAtIndex:0] msgId] inConversation:self.conversation];
    }
    
    [self.view addSubview:self.tableView];
    [self.tableView addSubview:self.slimeView];
    [self.view addSubview:self.inputController.view];
    [self addChildViewController:self.inputController];
    [self.inputController didMoveToParentViewController:self];
    [self updateSubViewFrame];
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    {
        IMMessage *cardMessage = [[IMMessage alloc] init];
        cardMessage.chat_t = eChatType_GroupChat;
        cardMessage.msg_t = eMessageType_TXT;
        IMTxtMessageBody*card = [[IMTxtMessageBody alloc] init];
        card.content = @"http://www.baidu.com";
        cardMessage.messageBody = card;
        [self addNewMessages:@[cardMessage] isForward:NO];
    }
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
    
    NSMutableArray *mutMessages = [[NSMutableArray alloc] initWithArray:messages];
    IMMessage *lastMessage = nil;
    if (!forward && self.messageList.count>0) {
        lastMessage = self.messageList.lastObject;
    }
    else if (forward || self.messageList.count<=0)
    {
        IMMessage *firstMessage = messages.firstObject;
        [mutMessages insertObject:[[NSDate dateWithTimeIntervalSince1970:firstMessage.createAt] formattedTime] atIndex:0];
    }
    
    for (IMMessage *oneMessage in messages) {
        [oneMessage markRead];
        if (lastMessage) {
            long long minute = ([NSDate dateWithTimeIntervalSince1970:oneMessage.createAt].minute - [NSDate dateWithTimeIntervalSince1970:lastMessage.createAt].minute );//两条消息的时间分单位间隔超过1，则加一个时间显示
            if (minute > 1) {
                [mutMessages insertObject:[[NSDate dateWithTimeIntervalSince1970:oneMessage.createAt] formattedTime] atIndex:[mutMessages indexOfObject:oneMessage]];
            }
        }
        else
            lastMessage = oneMessage;
    }

    if (forward) {
        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mutMessages.count)];
        [self.messageList insertObjects:mutMessages atIndexes:set];
        [self.tableView reloadData];
    }
    else
    {
        [self.messageList addObjectsFromArray:mutMessages];
        [self.tableView reloadData];
        [self scrollViewToBottom:YES];
    }

}

- (void)loadMoreMessages
{
    double_t msgId = 0;
    if (self.messageList.count>0) {
        IMMessage *message = [self.messageList objectAtIndex:0];
        msgId = message.msgId;
    }
    NSArray *messageList = [[BJIMManager shareInstance] loadMessageFromMinMsgId:msgId inConversation:self.conversation];
    [self addNewMessages:messageList isForward:YES];
    if (msgId != 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[messageList count] inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - observer 通知 进入前台，后台等
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateSubViewFrame];
}

- (void)applicationDidEnterBackgroud
{
    [[BJIMManager shareInstance] stopChat];
}

- (void)applicationDidBecomeActive
{
    if (self.chatInfo.chat_t == eChatType_GroupChat) {
        [[BJIMManager shareInstance] startChatToGroup:self.chatInfo.getToId];
    }
    else
    {
        [[BJIMManager shareInstance] startChatToUserId:self.chatInfo.getToId role:self.chatInfo.getToRole];
    }
}

#pragma mark - 视图更新
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self keyBoardHidden];
}

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
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}


- (void)showBigImageWithMessage:(IMMessage *)message
{
    @TODO("显示大图");
}

- (void)cardCellTapWithMessage:(IMMessage *)message
{
    @TODO("点击跳转代码");
}

- (void)linkCellTapWithMessage:(NSString *)str
{
    @TODO("点击链接跳转代码");
}

- (void)audioCellTapWithMessage:(IMMessage *)message
{
    __weak typeof(self) weakSelf = self;
    if (message.isPlaying) {
        [[BJChatAudioPlayerHelper sharedInstance] stopPlayerWithMessage:message];
    }
    else
    {
        [message markPlayed];
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
    else if ([eventName isEqualToString:kRouterEventAudioBubbleTapEventName])
    {
        [self audioCellTapWithMessage:message];
    }
    else if ([eventName isEqualToString:kRouterEventCardEventName])
    {
        [self cardCellTapWithMessage:message];
    }
    else if ([eventName isEqualToString:kRouterEventLinkName])
    {
        [self linkCellTapWithMessage:[userInfo objectForKey:kRouterEventUserInfoObject]];
    }
}

#pragma mark - slimeRefresh delegate
//加载更多
- (void)slimeRefreshStartRefresh:(SRRefreshView *)refreshView
{
    [self loadMoreMessages];
    [self.slimeView endRefresh];
}

#pragma mark - scrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.slimeView) {
        [self.slimeView scrollViewDidScroll];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self keyBoardHidden];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.slimeView) {
        [self.slimeView scrollViewDidEndDraging];
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
    
    if ([message isKindOfClass:[NSString class]]) {
        BJChatTimeCell *timeCell = (BJChatTimeCell *)[tableView dequeueReusableCellWithIdentifier:@"MessageCellTime"];
        if (timeCell == nil) {
            timeCell = [[BJChatTimeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MessageCellTime"];
            timeCell.backgroundColor = [UIColor clearColor];
            timeCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        timeCell.textLabel.text = (NSString *)message;
        
        return timeCell;
    }
    
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

    if ([message isKindOfClass:[NSString class]]) {
        return 40;
    }
    else
    {
        CGFloat Height = 0;
        
        //message的id自己发的不一定已经创建 需要以其他值为键
        //    if ([self.messageHeightDic objectForKey:@(message.msgId)]) {
        //        Height = [[self.messageHeightDic objectForKey:@(message.msgId)] floatValue];
        //    }
        //    else
        //    {
        Height = [[BJChatCellFactory sharedInstance] cellHeightWithMessage:message indexPath:indexPath];
        [self.messageHeightDic setObject:@(Height) forKeyedSubscript:@(message.msgId)];
        //    }
        return Height;
    }

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
            if (_conversation) {
                self.title = _conversation.chatToGroup.groupName;
            }
        }
        else
        {
        _conversation = [[BJIMManager shareInstance] getConversationUserId:self.chatInfo.getToId role:self.chatInfo.getToRole];
            if (_conversation) {
                self.title = _conversation.chatToUser.name;
            }
        }
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

- (SRRefreshView *)slimeView
{
    if (_slimeView == nil) {
        _slimeView = [[SRRefreshView alloc] init];
        _slimeView.delegate = self;
        _slimeView.upInset = 0;
        _slimeView.slimeMissWhenGoingBack = YES;
        _slimeView.slime.bodyColor = [UIColor grayColor];
        _slimeView.slime.skinColor = [UIColor grayColor];
        _slimeView.slime.lineWith = 1;
        _slimeView.slime.shadowBlur = 4;
        _slimeView.slime.shadowColor = [UIColor grayColor];
    }
    
    return _slimeView;
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
