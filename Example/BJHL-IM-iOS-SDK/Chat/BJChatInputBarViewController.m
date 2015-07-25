//
//  ChatInputViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInputBarViewController.h"

#define kInputTextViewMinHeight 36
#define kInputTextViewMaxHeight 84
#define kHorizontalPadding 4
#define kVerticalPadding 5

#define kTouchToRecord @"按住说话"
#define kTouchToFinish @"松开发送"

@interface BJChatInputBarViewController ()
@property (strong, nonatomic) Conversation *conversation;

/**
 *  用于输入文本消息的输入框
 */
@property (strong, nonatomic) XHMessageTextView *inputTextView;

/**
 *  文字输入区域最大高度，必须 > KInputTextViewMinHeight(最小高度)并且 < KInputTextViewMaxHeight，否则设置无效
 */
@property (nonatomic) CGFloat maxTextInputViewHeight;

@end

@implementation BJChatInputBarViewController

- (instancetype)initWithConversation:(Conversation *)conversation
{
    self = [super init];
    if (self) {
        _conversation = conversation;
    }
    return self;
}

- (void)loadView
{
    UIView *theView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [BJChatInputBarViewController defaultHeight])];
    self.view = theView;
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

#pragma mark - input View
- (void)willShowBottomView:(UIView *)bottomView;
{
    
}

+ (CGFloat)defaultHeight
{
    return kVerticalPadding * 2 + kInputTextViewMinHeight;
}

@end
