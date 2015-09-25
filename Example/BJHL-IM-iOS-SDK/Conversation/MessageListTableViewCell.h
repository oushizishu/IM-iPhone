//
//  MessageListTableViewCell.h
//  BJEducation_Institution
//
//  Created by Randy on 15/3/26.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JSBadgeView;
@interface MessageListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *badgeViewParent;

- (void)setBadgeNumber:(NSString *)numStr;

@end
