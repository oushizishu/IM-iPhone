//
//  BJChatInputBarViewController+BJRecordView.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInputBarViewController+BJRecordView.h"
#import "DXRecordView.h"
#import <BJAudioBufferRecorder.h>

static char BJRecordView_View;
static char BJRecordView_Recorder;

@interface BJChatInputBaseViewController ()
/**
 *  RecordView
 */
@property (strong, nonatomic) DXRecordView *recordView;
@property (strong, nonatomic) BJAudioBufferRecorder *recorder;
@end

@implementation BJChatInputBarViewController (BJRecordView)
- (void)bjrv_cancelTouchRecordView;
{
    [self.recordView recordButtonTouchUpInside];
    [self.recordView removeFromSuperview];
}

- (void)bjrv_setupRecordView:(UIButton *)button;
{
    [button addTarget:self action:@selector(recordButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(recordButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(recordButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(recordDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(recordDragInside) forControlEvents:UIControlEventTouchDragEnter];
}

- (void)recordButtonTouchDown
{
    [self.recordView recordButtonTouchDown];

    self.recordView.center = self.parentViewController.view.center;
    [self.parentViewController.view addSubview:self.recordView];
    [self.parentViewController.view bringSubviewToFront:self.recordView];
    
    __weak typeof(self) weakSelf = self;
    [self.recorder startRecord:^(BOOL isStart) {
        if (!isStart) {
            [weakSelf cancelTouchRecord];
        }
    }];
}

- (void)recordButtonTouchUpOutside
{
    [self.recordView recordButtonTouchUpOutside];
    [self.recorder cancelRecord];
    [self.recordView removeFromSuperview];
}

- (void)recordButtonTouchUpInside
{
    [self.recordView recordButtonTouchUpInside];
    [self.recordView removeFromSuperview];
    __weak typeof(self) weakSelf = self;
    self.recorder.finishCallback = ^(NSString *message,NSInteger timeLength,BOOL isSuc,BOOL isFinish){
        if (isSuc) {
            @TODO("添加录音成功提示。");
        }
        else if (isFinish) {
            [BJSendMessageHelper sendAudioMessage:message duration:timeLength chatInfo:weakSelf.chatInfo];
        }
        else
        {
            @TODO("添加提示按钮。");
        }
    };
    [self.recorder stopRecord];
}

- (void)recordDragOutside
{
    [self.recordView recordButtonDragOutside];
}

- (void)recordDragInside
{
    [self.recordView recordButtonDragInside];
}

#pragma mark - set get
- (DXRecordView *)recordView
{
    if (objc_getAssociatedObject(self, &BJRecordView_View) == nil) {
        [self setRecordView:[[DXRecordView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-140)/2, 130, 140, 140)]];
    }
    return objc_getAssociatedObject(self, &BJRecordView_View);
}

- (void)setRecordView:(DXRecordView *)recordView
{
    objc_setAssociatedObject(self, &BJRecordView_View, recordView, OBJC_ASSOCIATION_RETAIN);
}

- (BJAudioBufferRecorder *)recorder
{
    if (objc_getAssociatedObject(self, &BJRecordView_Recorder) == nil) {
        BJAudioBufferRecorder *recorder = [[BJAudioBufferRecorder alloc] init];
        recorder.duration = 0;
        [self setRecorder:recorder ];
    }
    return objc_getAssociatedObject(self, &BJRecordView_Recorder);
}

- (void)setRecorder:(BJAudioBufferRecorder *)recorder
{
    objc_setAssociatedObject(self, &BJRecordView_Recorder, recorder, OBJC_ASSOCIATION_RETAIN);
}

@end
