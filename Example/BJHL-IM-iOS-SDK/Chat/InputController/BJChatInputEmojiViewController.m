//
//  BJChatInputEmojiViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInputEmojiViewController.h"
#import "DXFaceView.h"
#import <PureLayout.h>
#import "BJSendMessageHelper.h"

@interface BJChatInputEmojiViewController()<DXFaceDelegate>
@property (strong, nonatomic) DXFaceView *faceView;
@end

@implementation BJChatInputEmojiViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.view addSubview:self.faceView];
    [self.faceView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

#pragma mark - action
- (void)sendFaceMessage:(NSString *)str
{
    [BJSendMessageHelper sendEmojiMessage:str chatInfo:self.chatInfo];
}

#pragma mark - DXFaceDelegate
- (void)selectThenSendImage:(UIImage *)img emoji:(NSString *)emoji
{
    if (img) {
        [self sendFaceMessage:emoji];
    }
}

#pragma mark - set get
- (DXFaceView *)faceView
{
    if (_faceView == nil) {
        _faceView = [[DXFaceView alloc] init];
        _faceView.backgroundColor = [UIColor clearColor];
        _faceView.delegate = self;
    }
    return _faceView;
}

@end
