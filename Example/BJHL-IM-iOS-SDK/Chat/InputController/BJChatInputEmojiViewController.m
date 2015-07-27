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
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200);
    self.view.autoresizingMask = UIViewAutoresizingNone;

    [self.view addSubview:self.faceView];
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
        _faceView = [[DXFaceView alloc] initWithFrame:self.view.bounds];
        _faceView.backgroundColor = [UIColor clearColor];
        _faceView.delegate = self;
    }
    return _faceView;
}

@end
