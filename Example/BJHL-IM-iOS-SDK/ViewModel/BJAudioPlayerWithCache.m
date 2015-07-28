//
//  BJAudioPlayerWithCache.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJAudioPlayerWithCache.h"

@implementation BJAudioPlayerWithCache

+ (instancetype)sharedInstance
{
    static BJAudioPlayerWithCache *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)startPlayer:(NSURL *)url;
{
    
}


@end
