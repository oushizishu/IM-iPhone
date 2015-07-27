//
//  BJChatInputProtocol.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BJChatInputProtocol <NSObject>
@optional
/**
 *  高度变到toHeight
 */
- (void)didChangeFrameToHeight:(CGFloat)toHeight;

- (void)chatInputDidEndEdit;

@end
