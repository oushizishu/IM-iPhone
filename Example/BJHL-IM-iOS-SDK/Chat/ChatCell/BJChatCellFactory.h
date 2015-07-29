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

extern const NSInteger unKownChatMessageType;
extern const NSInteger unKownSysMessageType;

@interface BJChatCellFactory : NSObject

+ (instancetype)sharedInstance;
#pragma mark - Cell Class
/**
 *  根据消息类型返回对应的cell，如果此类型没有cell注册处理，默认会返回不支持版本的cell
 *
 *  @param type 消息类型
 *
 *  @return cell
 */
- (UITableViewCell<BJChatViewCellProtocol> *)cellWithMessageType:(IMMessageType)type;
- (NSString *)cellIdentifierWithMessageType:(IMMessageType)type;

/**
 *  cell调用此方法去注册要处理的消息类型，后注册的覆盖前注册的。一个cell可注册多个消息类型
 *
 *  @param cellClass Class
 *  @param type      消息类型
 */
- (void)registerClass:(Class)cellClass forMessageType:(IMMessageType)type;

/**
 *  检查某个消息类型是否有cell注册可以处理
 *
 *  @param type 消息类型
 *
 *  @return 可以处理：YES
 */
- (BOOL)canHandleMessageType:(IMMessageType)type;

- (CGFloat)cellHeightWithMessage:(IMMessage *)message indexPath:(NSIndexPath *)indexPath;

@end
