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
#import "BJChatInputProtocol.h"

@interface BJChatInputBaseViewController : UIViewController
@property (strong, readonly, nonatomic) BJChatInfo *chatInfo;
@property (weak, nonatomic) id<BJChatInputProtocol> delegate;

- (instancetype)initWithChatInfo:(BJChatInfo *)chatInfo;
@end
