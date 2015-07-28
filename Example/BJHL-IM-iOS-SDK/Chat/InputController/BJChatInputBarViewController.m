//
//  ChatInputViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInputBarViewController.h"
#import "BJChatInputBarViewController+BJRecordView.h"
#import "BJChatInputMoreViewController.h"
#import "BJChatInputEmojiViewController.h"
#define kInputTextViewMinHeight 36
#define kInputTextViewMaxHeight 84
#define kHorizontalPadding 4
#define kVerticalPadding 5

#define kTouchToRecord @"按住说话"
#define kTouchToFinish @"松开发送"

@interface BJChatInputBarViewController ()<UITextViewDelegate,BJChatInputProtocol>
/**
 *  用于输入文本消息的输入框
 */
@property (strong, nonatomic) XHMessageTextView *inputTextView;

/**
 *  文字输入区域最大高度，必须 > KInputTextViewMinHeight(最小高度)并且 < KInputTextViewMaxHeight，否则设置无效
 */
@property (nonatomic) CGFloat maxTextInputViewHeight;


/**
 *  按钮、输入框、toolbarView
 */
@property (strong, nonatomic) UIView *toolbarView;
@property (strong, nonatomic) UIButton *styleChangeButton;
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIButton *faceButton;
@property (strong, nonatomic) UIButton *recordButton;
@property (assign, nonatomic) CGFloat previousTextViewContentHeight;//上一次inputTextView的contentSize.height

/**
 *  底部扩展页面
 */
@property (nonatomic) BOOL isShowButtomView;
@property (strong, nonatomic) UIView *activityButtomView;

/**
 *  子视图控制器
 */
@property (strong, nonatomic) BJChatInputEmojiViewController *emojiViewController;
@property (strong, nonatomic) BJChatInputMoreViewController *moreViewController;
@end

@implementation BJChatInputBarViewController

- (instancetype)initWithChatInfo:(BJChatInfo *)chatInfo
{
    self = [super initWithChatInfo:chatInfo];
    if (self) {
        [self setupConfigure];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    
    _inputTextView.delegate = nil;
    _inputTextView = nil;
}

- (void)loadView
{
    UIView *theView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [BJChatInputBarViewController defaultHeight])];
    self.view = theView;
    [self setupSubviews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
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

#pragma mark - 初始化
- (void)setupConfigure
{
    self.maxTextInputViewHeight = kInputTextViewMaxHeight;
    [self.view addSubview:self.toolbarView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)setupSubviews
{
    CGFloat allButtonWidth = 0.0;
    CGFloat textViewLeftMargin = 6.0;
    
    //转变输入样式
    self.styleChangeButton = [[UIButton alloc] initWithFrame:CGRectMake(kHorizontalPadding, kVerticalPadding, kInputTextViewMinHeight, kInputTextViewMinHeight)];
    self.styleChangeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.styleChangeButton setImage:[UIImage imageNamed:@"ic_microphone_nor_.png"] forState:UIControlStateNormal];
    [self.styleChangeButton setImage:[UIImage imageNamed:@"ic_keyboard_nor_.png"] forState:UIControlStateSelected];
    [self.styleChangeButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.styleChangeButton.tag = 0;
    allButtonWidth += CGRectGetMaxX(self.styleChangeButton.frame);
    textViewLeftMargin += CGRectGetMaxX(self.styleChangeButton.frame);
    
    //更多
    self.moreButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - kHorizontalPadding - kInputTextViewMinHeight, kVerticalPadding, kInputTextViewMinHeight, kInputTextViewMinHeight)];
    self.moreButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.moreButton setImage:[UIImage imageNamed:@"ic_add_normal"] forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage imageNamed:@"ic_add_press"] forState:UIControlStateHighlighted];
    [self.moreButton setImage:[UIImage imageNamed:@"ic_keyboard_nor_"] forState:UIControlStateSelected];
    [self.moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.moreButton.tag = 2;
    allButtonWidth += CGRectGetWidth(self.moreButton.frame) + kHorizontalPadding * 2.5;
    
    //表情
    self.faceButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.moreButton.frame) - kInputTextViewMinHeight - kHorizontalPadding, kVerticalPadding, kInputTextViewMinHeight, kInputTextViewMinHeight)];
    self.faceButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.faceButton setImage:[UIImage imageNamed:@"ic_expression_normal"] forState:UIControlStateNormal];
    [self.faceButton setImage:[UIImage imageNamed:@"ic_expression_press"] forState:UIControlStateHighlighted];
    [self.faceButton setImage:[UIImage imageNamed:@"ic_keyboard_nor_"] forState:UIControlStateSelected];
    [self.faceButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.faceButton.tag = 1;
    allButtonWidth += CGRectGetWidth(self.faceButton.frame) + kHorizontalPadding * 1.5;
    
    // 输入框的高度和宽度
    CGFloat width = CGRectGetWidth(self.view.bounds) - (allButtonWidth ? allButtonWidth : (textViewLeftMargin * 2));
    // 初始化输入框
    self.inputTextView = [[XHMessageTextView  alloc] initWithFrame:CGRectMake(textViewLeftMargin, kVerticalPadding, width, kInputTextViewMinHeight)];
    self.inputTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    //    self.inputTextView.contentMode = UIViewContentModeCenter;
    self.inputTextView.scrollEnabled = YES;
    self.inputTextView.returnKeyType = UIReturnKeySend;
    self.inputTextView.enablesReturnKeyAutomatically = YES; // UITextView内部判断send按钮是否可以用
    self.inputTextView.placeHolder = @"说点什么吧...";
    self.inputTextView.delegate = self;
    self.inputTextView.backgroundColor = [UIColor clearColor];
    self.inputTextView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.inputTextView.layer.borderWidth = 0.65f;
    self.inputTextView.layer.cornerRadius = 6.0f;
    self.previousTextViewContentHeight = [self getTextViewContentH:self.inputTextView];
    
    //录制
    self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(textViewLeftMargin, kVerticalPadding, width, kInputTextViewMinHeight)];
    self.recordButton.clipsToBounds = YES;
    self.recordButton.layer.cornerRadius = 6.0f;
    self.recordButton.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.recordButton.layer.borderWidth = 0.65f;
    self.recordButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.recordButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.recordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.recordButton setBackgroundImage:[UIImage imageNamed:@"bg_white"] forState:UIControlStateNormal];
    [self.recordButton setBackgroundImage:[[UIImage imageNamed:@"chatBar_recordSelectedBg"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateHighlighted];
    [self.recordButton setTitle:kTouchToRecord forState:UIControlStateNormal];
    [self.recordButton setTitle:kTouchToFinish forState:UIControlStateHighlighted];
    self.recordButton.hidden = YES;
    [self bjrv_setupRecordView:self.recordButton];
    
    [self.toolbarView addSubview:self.styleChangeButton];
    [self.toolbarView addSubview:self.moreButton];
    [self.toolbarView addSubview:self.faceButton];
    [self.toolbarView addSubview:self.inputTextView];
    [self.toolbarView addSubview:self.recordButton];
}

#pragma mark - Public
/**
 *  停止编辑
 */
- (BOOL)endEditing:(BOOL)force
{
    BOOL result = [self.view endEditing:force];
    
    self.faceButton.selected = NO;
    self.moreButton.selected = NO;
    [self willShowBottomView:nil];
    
    return result;
}

/**
 *  取消触摸录音键
 */
- (void)cancelTouchRecord
{
    self.recordButton.selected = NO;
    self.recordButton.highlighted = NO;
    [self bjrv_cancelTouchRecordView];
}

+ (CGFloat)defaultHeight
{
    return kVerticalPadding * 2 + kInputTextViewMinHeight;
}

#pragma mark - action

- (void)buttonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    NSInteger tag = button.tag;
    
    switch (tag) {
        case 0://切换状态
        {
            if (button.selected) {
                self.faceButton.selected = NO;
                self.moreButton.selected = NO;
                //录音状态下，不显示底部扩展页面
                [self willShowBottomView:nil];
                
                //将inputTextView内容置空，以使toolbarView回到最小高度
                self.inputTextView.text = @"";
                [self textViewDidChange:self.inputTextView];
                [self.inputTextView resignFirstResponder];
            }
            else{
                //键盘也算一种底部扩展页面
                [self.inputTextView becomeFirstResponder];
            }
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.recordButton.hidden = !button.selected;
                self.inputTextView.hidden = button.selected;
            } completion:^(BOOL finished) {
                
            }];
        }
            break;
        case 1://表情
        {
            if (button.selected) {
                self.moreButton.selected = NO;
                //如果选择表情并且处于录音状态，切换成文字输入状态，但是不显示键盘
                if (self.styleChangeButton.selected) {
                    self.styleChangeButton.selected = NO;
                }
                else{//如果处于文字输入状态，使文字输入框失去焦点
                    [self.inputTextView resignFirstResponder];
                }
                
                [self willShowBottomView:self.emojiViewController.view];
                [self.emojiViewController didMoveToParentViewController:self];
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.recordButton.hidden = button.selected;
                    self.inputTextView.hidden = !button.selected;
                } completion:^(BOOL finished) {
                    
                }];
            } else {
                if (!self.styleChangeButton.selected) {
                    [self.inputTextView becomeFirstResponder];
                }
                else{
                    [self willShowBottomView:nil];
                }
            }
        }
            break;
        case 2://更多
        {
            if (button.selected) {
                self.faceButton.selected = NO;
                //如果选择表情并且处于录音状态，切换成文字输入状态，但是不显示键盘
                if (self.styleChangeButton.selected) {
                    self.styleChangeButton.selected = NO;
                }
                else{//如果处于文字输入状态，使文字输入框失去焦点
                    [self.inputTextView resignFirstResponder];
                }
                
                [self willShowBottomView:self.moreViewController.view];
                [self.emojiViewController didMoveToParentViewController:self];
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.recordButton.hidden = button.selected;
                    self.inputTextView.hidden = !button.selected;
                } completion:^(BOOL finished) {
                    
                }];
            }
            else
            {
                self.styleChangeButton.selected = NO;
                [self.inputTextView becomeFirstResponder];
            }
            break;
        }
        case 4:
        {
//            [_delegate toolBarPhotoAction];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Notification
- (void)applicationDidEnterBackground
{
    [self cancelTouchRecord];
    
    //保存草稿
//    [self saveToDraft:self.chatToolBar.inputTextView];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    void(^animations)() = ^{
        //[self willShowKeyboardFromFrame:beginFrame toFrame:endFrame];
        [self willShowKeyboardFromFrame:beginFrame toFrame:endFrame withDuration:duration withAnimationOption:curve];
    };
    
    void(^completion)(BOOL) = ^(BOOL finished){
    };
    
    [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:completion];
}

#pragma mark - input View
- (void)removeBottomView
{
    if (self.activityButtomView) {
        if (self.moreViewController.view == self.activityButtomView) {
            [self.moreViewController willMoveToParentViewController:nil];
        }
        else if (self.emojiViewController.view == self.activityButtomView)
        {
            [self.emojiViewController willMoveToParentViewController:nil];
        }
        [self.activityButtomView removeFromSuperview];
    }
}

- (void)willShowBottomView:(UIView *)bottomView;
{
    [self willShowBottomView:bottomView withDuration:0.25];
}

/*!
 *  @author MrLu, 15-02-27 23:02:27
 *  modify add duration
 *  @brief  按钮点击键盘变化
 *  @param bottomView bottomView
 *  @param duration   动画时间
 */
- (void)willShowBottomView:(UIView *)bottomView withDuration:(CGFloat)duration
{
    if (![self.activityButtomView isEqual:bottomView]) {
        CGFloat bottomHeight = bottomView ? bottomView.frame.size.height : 0;
        [self willShowBottomHeight:bottomHeight withDuration:duration withAnimationOption:UIViewAnimationCurveEaseInOut completion:^(BOOL finished) {
            
        }];
        if (bottomView) {
            CGRect rect = bottomView.frame;
            rect.origin.y = CGRectGetMaxY(self.toolbarView.frame);
            bottomView.frame = rect;
            [self.view addSubview:bottomView];
        }
        
        [self removeBottomView];
        self.activityButtomView = bottomView;
    }
}

/*!
 *  @author MrLu, 15-02-27 19:02:59
 *  modify: add duration & animationCurve
 *  @brief  键盘变化
 *
 *  @param beginFrame     初始frame
 *  @param toFrame        目的frame
 *  @param duration       时间间隔  add
 *  @param animationCurve 动画类型  add
 */
- (void)willShowKeyboardFromFrame:(CGRect)beginFrame toFrame:(CGRect)toFrame withDuration:(CGFloat)duration withAnimationOption:(UIViewAnimationCurve)animationCurve
{
    if (beginFrame.origin.y == [[UIScreen mainScreen] bounds].size.height)
    {
        //一定要把self.activityButtomView置为空
        [self willShowBottomHeight:toFrame.size.height withDuration:duration withAnimationOption:animationCurve completion:^(BOOL finished) {
            
        }];
        [self removeBottomView];
        self.activityButtomView = nil;
    }
    else if (toFrame.origin.y == [[UIScreen mainScreen] bounds].size.height)
    {
        [self willShowBottomHeight:0 withDuration:duration withAnimationOption:animationCurve completion:^(BOOL finished) {
            
        }];
    }
    else{
        [self willShowBottomHeight:toFrame.size.height withDuration:duration withAnimationOption:animationCurve completion:^(BOOL finished) {
            
        }];
    }
}

/*!
 *  @author MrLu, 15-02-27 19:02:42
 *  modify: add duration & animationCurve
 *  @brief  键盘变化
 *
 *  @param bottomHeight 底部高度
 *  @param duration       时间间隔  add
 *  @param animationCurve 动画类型  add
 *  @param completion   completion description
 */
- (void)willShowBottomHeight:(CGFloat)bottomHeight withDuration:(CGFloat)duration withAnimationOption:(UIViewAnimationCurve)animationCurve completion:(void (^)(BOOL finished))completion
{
    CGRect fromFrame = self.view.frame;
    CGFloat toHeight = self.toolbarView.frame.size.height + bottomHeight;
    CGRect toFrame = CGRectMake(fromFrame.origin.x, fromFrame.origin.y + (fromFrame.size.height - toHeight), fromFrame.size.width, toHeight);
    
    //如果需要将所有扩展页面都隐藏，而此时已经隐藏了所有扩展页面，则不进行任何操作
    if(bottomHeight == 0 && self.view.frame.size.height == self.toolbarView.frame.size.height)
    {
        return;
    }
    
    if (bottomHeight == 0) {
        self.isShowButtomView = NO;
    }
    else{
        self.isShowButtomView = YES;
    }
    
    [UIView animateWithDuration:duration delay:0 options:(animationCurve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        self.view.frame = toFrame;
        if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeFrameToHeight:)]) {
            [self.delegate didChangeFrameToHeight:toHeight];
        }
    } completion:^(BOOL finished) {
        if (finished) {
            completion(finished);
        }
    }];
}

- (CGFloat)getTextViewContentH:(UITextView *)textView
{
    CGFloat thatHeight = ([textView sizeThatFits:textView.frame.size].height);
    CGFloat height = textView.contentSize.height;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        return ceilf(thatHeight);
    } else {
        return height;
    }
}

- (void)willShowInputTextViewToHeight:(CGFloat)toHeight
{
    if (toHeight < kInputTextViewMinHeight) {
        toHeight = kInputTextViewMinHeight;
    }
    if (toHeight > self.maxTextInputViewHeight) {
        toHeight = self.maxTextInputViewHeight;
    }
    
    if (toHeight == _previousTextViewContentHeight)
    {
        return;
    }
    else{
        CGFloat changeHeight = toHeight - _previousTextViewContentHeight;
        
        CGRect rect = self.view.frame;
        rect.size.height += changeHeight;
        rect.origin.y -= changeHeight;
        self.view.frame = rect;
        
        rect = self.toolbarView.frame;
        rect.size.height += changeHeight;
        self.toolbarView.frame = rect;
        
        if (self.activityButtomView){
            rect = self.activityButtomView.frame;
            rect.origin.y += changeHeight;
            self.activityButtomView.frame = rect;
        }
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
            [self.inputTextView setContentOffset:CGPointMake(0.0f, (self.inputTextView.contentSize.height - self.inputTextView.frame.size.height) / 2) animated:YES];
        }
        else
            [self.inputTextView setContentOffset:self.inputTextView.contentOffset animated:YES];
        _previousTextViewContentHeight = toHeight;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeFrameToHeight:)]) {
            [self.delegate didChangeFrameToHeight:self.view.frame.size.height];
        }
    }
}

#pragma mark - BJChatInputProtocol
- (void)chatInputDidEndEdit;
{
    [self endEditing:YES];
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    self.faceButton.selected = NO;
    self.styleChangeButton.selected = NO;
    self.moreButton.selected = NO;
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    if ([text isEqualToString:@"\n"]) {
        [BJSendMessageHelper sendTextMessage:textView.text chatInfo:self.chatInfo];
        self.inputTextView.text = @"";
        [self willShowInputTextViewToHeight:[self getTextViewContentH:self.inputTextView]];
        
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat height = [self getTextViewContentH:textView];
    [self willShowInputTextViewToHeight:height];
}

#pragma mark - set get
- (void)setMaxTextInputViewHeight:(CGFloat)maxTextInputViewHeight
{
    if (maxTextInputViewHeight > kInputTextViewMaxHeight) {
        maxTextInputViewHeight = kInputTextViewMaxHeight;
    }
    _maxTextInputViewHeight = maxTextInputViewHeight;
}

- (UIView *)toolbarView
{
    if (_toolbarView == nil) {
        _toolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BJChatInputBarViewController defaultHeight])];
        _toolbarView.backgroundColor = [UIColor clearColor];
    }
    
    return _toolbarView;
}

- (BJChatInputMoreViewController *)moreViewController
{
    if (_moreViewController == nil) {
        _moreViewController = [[BJChatInputMoreViewController alloc] initWithChatInfo:self.chatInfo];
        _moreViewController.view.frame = CGRectMake(0, (kVerticalPadding * 2 + kInputTextViewMinHeight), _moreViewController.view.frame.size.width, _moreViewController.view.frame.size.height);
        [self addChildViewController:_moreViewController];
        _moreViewController.delegate = self;
    }
    return _moreViewController;
}

- (BJChatInputEmojiViewController *)emojiViewController
{
    if (_emojiViewController == nil) {
        _emojiViewController = [[BJChatInputEmojiViewController alloc] initWithChatInfo:self.chatInfo];
        _emojiViewController.view.frame = CGRectMake(0, (kVerticalPadding * 2 + kInputTextViewMinHeight), _emojiViewController.view.frame.size.width, _emojiViewController.view.frame.size.height);
        [self addChildViewController:_emojiViewController];
        _emojiViewController.delegate = self;
    }
    return _emojiViewController;
}

@end
