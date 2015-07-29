//
//  ChatCellFactory.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatCellFactory.h"
#import <IMMessage.h>

const NSInteger unKownChatMessageType = -100;
const NSInteger unKownSysMessageType = -100;

static BJChatCellFactory *sharedInstance = nil;

@interface BJChatCellFactory ()
@property (strong, nonatomic) NSMutableDictionary *registerCellDic;
@end

@implementation BJChatCellFactory

+ (instancetype)sharedInstance
{
    static dispatch_once_t ChatCellFactoryOnceToken;
    
    dispatch_once(&ChatCellFactoryOnceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - Cell Class
- (Class)classWithMessageType:(IMMessageType)type
{
    id key = @(type);
    if (![self canHandleMessageType:type]) {
//        NSAssert1(0, @"%ld 此类型没有支持的cell显示，请实现此cell并调用 BJChatCellFactory 的注册方法 registerClass:forMessageType", type);
        if (type == eMessageType_NOTIFICATION) {
            key = @(unKownSysMessageType);
        }
        else
            key = @(unKownChatMessageType);
    }
    
    Class cellClass = [self.registerCellDic objectForKey:key];
    return cellClass;
}

- (UITableViewCell<BJChatViewCellProtocol> *)cellWithMessageType:(IMMessageType)type
{
    Class cellClass = [self classWithMessageType:type];
    UITableViewCell<BJChatViewCellProtocol> *cell = [[cellClass alloc] init];
    if ([cell conformsToProtocol:@protocol(BJChatViewCellProtocol)]) {
        return cell;
    }
    else
    {
        NSAssert1(0, @"%@ 需要遵循 BJChatViewCellProtocol协议",NSStringFromClass(cellClass));
        return nil;
    }
}

- (NSString *)cellIdentifierWithMessageType:(IMMessageType)type;
{
    Class cellClass = [self classWithMessageType:type];
    return NSStringFromClass(cellClass);
}

- (void)registerClass:(Class)cellClass forMessageType:(IMMessageType)type
{
    NSAssert(cellClass, @"class 不能为空");
    NSAssert([cellClass isSubclassOfClass:[UITableViewCell class]], @"cell必须是UITableViewCell的子类");
    if (cellClass != nil && [cellClass isSubclassOfClass:[UITableViewCell class]]) {
        [self.registerCellDic setObject:cellClass forKey:@(type)];
    }
}

- (BOOL)canHandleMessageType:(IMMessageType)type
{
    return [self.registerCellDic objectForKey:@(type)];
}

- (CGFloat)cellHeightWithMessage:(IMMessage *)message indexPath:(NSIndexPath *)indexPath;
{
    Class cellClass = [self classWithMessageType:message.msg_t];
    if (cellClass) {
        return [cellClass cellHeightWithInfo:message indexPath:indexPath];
    }
    else
        return 0;
}

#pragma makr - set get
- (NSMutableDictionary *)registerCellDic
{
    if (_registerCellDic == nil) {
        _registerCellDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return _registerCellDic;
}

@end
