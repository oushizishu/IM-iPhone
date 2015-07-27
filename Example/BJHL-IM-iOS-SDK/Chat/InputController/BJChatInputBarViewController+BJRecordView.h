//
//  BJChatInputBarViewController+BJRecordView.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInputBarViewController.h"
#import "DXRecordView.h"
@interface BJChatInputBarViewController (BJRecordView)

- (void)bjrv_cancelTouchRecordView;
- (void)bjrv_setupRecordView:(UIButton *)button;

@end
