/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "DXRecordView.h"
@interface DXRecordView ()
{
    NSTimer *_timer;
    
}

@end

@implementation DXRecordView
@synthesize recordAnimationView = _recordAnimationView;
@synthesize textLabel = _textLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//        UIView *bgView = [[UIView alloc] initWithFrame:self.bounds];
//        bgView.backgroundColor = [UIColor grayColor];
//        bgView.layer.cornerRadius = 5;
//        bgView.layer.masksToBounds = YES;
//        bgView.alpha = 0.6;
//        [self addSubview:bgView];
        
        _recordAnimationView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, self.bounds.size.width - 20, self.bounds.size.height - 10)];
        _recordAnimationView.image = [UIImage imageNamed:@"VoiceSearchFeedback001"];
        [self addSubview:_recordAnimationView];
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                               self.bounds.size.height - 35,
                                                               self.bounds.size.width - 20,
                                                               25)];
        
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.text = @" 手指上滑，取消发送 ";
        [self addSubview:_textLabel];
        _textLabel.font = [UIFont systemFontOfSize:12];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.layer.cornerRadius = 5;
        _textLabel.layer.borderColor = [[UIColor redColor] colorWithAlphaComponent:0.5].CGColor;
        _textLabel.layer.masksToBounds = YES;
    }
    return self;
}

// 录音按钮按下
-(void)recordButtonTouchDown
{
    // 需要根据声音大小切换recordView动画
    _textLabel.text = @" 手指上滑，取消发送 ";
    _textLabel.backgroundColor = [UIColor clearColor];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                              target:self
                                            selector:@selector(setVoiceImage)
                                            userInfo:nil
                                             repeats:YES];
    
}
// 手指在录音按钮内部时离开
-(void)recordButtonTouchUpInside
{
    [_timer invalidate];
}
// 手指在录音按钮外部时离开
-(void)recordButtonTouchUpOutside
{
    [_timer invalidate];
}
// 手指移动到录音按钮内部
-(void)recordButtonDragInside
{
    _textLabel.text = @" 手指上滑，取消发送 ";
    _textLabel.backgroundColor = [UIColor clearColor];
}

// 手指移动到录音按钮外部
-(void)recordButtonDragOutside
{
    _textLabel.text = @" 松开手指，取消发送 ";
    _textLabel.backgroundColor = [UIColor redColor];
}

-(void)setVoiceImage {
    _recordAnimationView.image = [UIImage imageNamed:@"VoiceSearchFeedback001"];
    float voiceSound = 0;
    voiceSound = [self.delegate getAudioMeter];
    NSLog(@"setVoiceImage %f",voiceSound);
    if (0 < voiceSound <= 0.05) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"ic_volume_1"]];
    }else if (0.05<voiceSound<=0.33) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"ic_volume_2"]];
    }else if (0.33<voiceSound<=0.5) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"ic_volume_3"]];
    }else if (0.5<voiceSound<=0.667) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"ic_volume_4"]];
    }else if (0.667<voiceSound<=0.833) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"ic_volume_5"]];
    }else {
        [_recordAnimationView setImage:[UIImage imageNamed:@"ic_volume_6"]];
    }
}

@end
