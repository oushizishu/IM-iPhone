//
//  BJAudioPlayer.h
//  BJEducation
//
//  Created by Randy on 14/11/29.
//  Copyright (c) 2014年 com.bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^AudioPlayerCallback)(NSString *message, BOOL isFinish);
typedef void (^AudioPlayerProressCallback)(CGFloat currentTime,CGFloat totalTime);
@interface BJAudioPlayer : NSObject
/**
 *  当调用stopPlay 时，不会回调此方法
 */
@property (copy, nonatomic)AudioPlayerCallback callback;

@property (copy, nonatomic)AudioPlayerProressCallback proressCallback;

- (BOOL)startPlayWithUrl:(NSURL *)url;
- (void)stopPlay;
@end
