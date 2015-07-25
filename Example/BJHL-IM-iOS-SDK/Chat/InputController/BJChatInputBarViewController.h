//
//  ChatInputViewController.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJChatInputBaseViewController.h"
#import "XHMessageTextView.h"

@protocol BJMessageToolBarDelegate <NSObject>

@required
/**
 *  高度变到toHeight
 */
- (void)didChangeFrameToHeight:(CGFloat)toHeight;

@end

@interface BJChatInputBarViewController : BJChatInputBaseViewController
@property (nonatomic, weak) id <BJMessageToolBarDelegate> delegate;
/**
 *  停止编辑
 */
- (BOOL)endEditing:(BOOL)force;
/**
 *  取消触摸录音键
 */
- (void)cancelTouchRecord;
+ (CGFloat)defaultHeight;

@end
