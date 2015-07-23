//
//  ConversationTableViewCell.h
//  BJHL-IM-iOS-SDK
//
//  Created by 杨磊 on 15/7/20.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJHL-Common-iOS-SDK/UIView+Basic.h>
#import <BJHL-IM-iOS-SDK/Conversation.h>

@interface BJConversationTableViewCell : UITableViewCell

@property (nonatomic, strong) Conversation *conversation;

@end
