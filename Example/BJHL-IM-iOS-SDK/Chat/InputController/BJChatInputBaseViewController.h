//
//  ChatInputBaseViewController.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/25.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJChatInfo.h"
#import "BJSendMessageHelper.h"

@interface BJChatInputBaseViewController : UIViewController
@property (strong, readonly, nonatomic) BJChatInfo *chatInfo;
- (instancetype)initWithChatInfo:(BJChatInfo *)chatInfo;
@end
