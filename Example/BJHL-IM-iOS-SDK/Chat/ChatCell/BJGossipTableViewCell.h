//
//  BJTipTextTableViewCell.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/29.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IMMessage.h>
#import "BJChatViewCellProtocol.h"
@interface BJGossipTableViewCell : UITableViewCell<BJChatViewCellProtocol>
@property (strong, nonatomic)IMMessage *message;
@property (strong, nonatomic)NSIndexPath *indexPath;
@end
