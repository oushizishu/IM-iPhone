//
//  ChatBaseViewController.h
//  BJEducation_Institution
//
//  Created by Randy on 15/4/6.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import "BJContactInfoProtocol.h"
#import "BJChatViewController.h"
@interface ChatBaseViewController : UIViewController
@property (strong, nonatomic) id<BJContactInfoProtocol>contact;
@property (strong, nonatomic) BJChatViewController *chatViewController;
- (instancetype)initWithContactId:(long long)userId contactRole:(BJContactType)type;
@end
