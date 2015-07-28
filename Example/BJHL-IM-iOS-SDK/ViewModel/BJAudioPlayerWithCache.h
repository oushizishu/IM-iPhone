//
//  BJAudioPlayerWithCache.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BJAudioPlayerWithCache : NSObject
- (void)startPlayer:(NSURL *)url;
- (void)stopPlayer;
- (void)isPlayerWithUrl:(NSURL *)url;
@end
