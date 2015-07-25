//
//  ChatCellFactory.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BJChatViewCellProtocol.h"
#import <BJIMConstants.h>

#define ChatCellFactoryInstance [BJChatCellFactory sharedInstance]

extern const NSInteger unKownMessageType;

@interface BJChatCellFactory : NSObject

+ (instancetype)sharedInstance;
#pragma mark - Cell Class
- (UITableViewCell<BJChatViewCellProtocol> *)cellWithMessageType:(IMMessageType)type;
- (NSString *)cellIdentifierWithMessageType:(IMMessageType)type;

- (void)registerClass:(Class)cellClass forMessageType:(IMMessageType)type;

- (BOOL)canHandleMessageType:(IMMessageType)type;

- (CGFloat)cellHeightWithMessage:(IMMessage *)message indexPath:(NSIndexPath *)indexPath;

@end
