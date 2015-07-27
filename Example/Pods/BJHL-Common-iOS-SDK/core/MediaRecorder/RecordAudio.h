//
//  RecordAudio.h
//
//  Created by Randy on 14-11-27.
//  Copyright (c) 2014年 com.bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
/**
 *  <#Description#>
 *
 *  @param message    <#message description#>
 *  @param timeLength <#timeLength description#>
 *  @param isSuc      <#isSuc description#>
 *  @param isFinish   是否已完成，可能是录制正在执行其他操作，会返回两次，第一次是录制完 isFinish=NO,第二次是处理完其他操作 isFinish= YES
 */
typedef void(^RecordAudioFinish)(NSString *message,NSInteger timeLength,BOOL isSuc,BOOL isFinish);
typedef void (^RecordRemainingTime)(CGFloat time);
@interface RecordAudio : NSObject <AVAudioRecorderDelegate>

/**
 *  duration==0,则不限制录制时间
 */
@property (assign, nonatomic)NSTimeInterval duration;
@property (copy, nonatomic)RecordRemainingTime remainingCallback;
@property (copy, nonatomic)RecordAudioFinish finishCallback;
- (void)stopRecord;
- (void)startRecord;
-(void)cancelRecord;

- (BOOL)isRecording;

@end
