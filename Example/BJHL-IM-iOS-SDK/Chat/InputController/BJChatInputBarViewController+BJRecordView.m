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
#import <JLMicrophonePermission.h>

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
    __weak typeof(self) weakSelf = self;
    //如果还没有获取授权，则按住效果会被打断
    if ([[JLMicrophonePermission sharedInstance] authorizationStatus] == JLPermissionAuthorized) {
        weakSelf.recordView.center = weakSelf.parentViewController.view.center;
        [weakSelf.parentViewController.view addSubview:weakSelf.recordView];
        [weakSelf.parentViewController.view bringSubviewToFront:weakSelf.recordView];
        [weakSelf.recordView recordButtonTouchDown];
        [self.recorder startRecord:^(BOOL isStart) {
            
        }];
    }
    else
    {
        [[JLMicrophonePermission sharedInstance] authorize:^(bool granted, NSError *error) {
            
        }];

    }
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
        if (isFinish) {
            [BJSendMessageHelper sendAudioMessage:message duration:timeLength chatInfo:weakSelf.chatInfo];
        }
        else if (isSuc) {
            @TODO("添加录音成功提示。");
        }
        else
        {
            @TODO("添加提示。");
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
