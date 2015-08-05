//
//  BJIMConstants.h
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#ifndef BJIM_BJIMConstants_h
#define BJIM_BJIMConstants_h


#pragma mark - im version.
#define BJIM_VERSTION @"1.0"

#import <LKDBHelper/NSObject+LKModel.h>
#import <Mantle/Mantle.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDLegacyMacros.h>

#pragma mark - 接口返回成功码
#define RESULT_CODE_SUCC 0


#pragma mark - 服务器环境
typedef NS_ENUM(NSInteger, IMSERVER_ENVIRONMENT)
{
    eIMServer_Environment_test = 0,
    eIMServer_Environment_beta = 1,
    eIMServer_Environment_www = 2,
    
};

#pragma mark - 用户角色
typedef NS_ENUM(NSInteger, IMUserRole)
{
    eUserRole_Teacher = 0,
    eUserRole_Student = 2,
    eUserRole_Institution = 6,
    eUserRole_Kefu = 7,
    eUserRole_System = 100, //系统通知
    eUserRole_Anonymous = -1,
};

#pragma mark - 消息类型
typedef NS_ENUM(NSInteger, IMMessageType)
{
    eMessageType_TXT = 0,
    eMessageType_IMG = 1,
    eMessageType_AUDIO = 2,
    eMessageType_LOCATION = 3,
    eMessageType_NOTIFICATION = 4,
    eMessageType_CARD = 5,
    eMessageType_EMOJI = 6,
    eMessageType_CMD = 7,
};

#pragma mark - 消息状态
typedef NS_ENUM(NSInteger, IMMessageStatus)
{
    eMessageStatus_init = 0,
    eMessageStatus_Sending = 1,
    eMessageStatus_Send_Succ = 2,
    eMessageStatus_Send_Fail = 3,
};

#pragma mark - 聊天类型
typedef NS_ENUM(NSInteger, IMChatType) {
    eChatType_Chat = 0, // 单聊
    eChatType_GroupChat = 1 // 群聊
};
static const int MESSAGE_PAGE_COUNT = 30;
static const double UNAVALIABLE_MESSAGE_ID =  -1;

#pragma mark - delegates
@protocol IMConversationChangedDelegate <NSObject>

- (void)didConversationDidChanged;

@end

@protocol IMReceiveNewMessageDelegate <NSObject>

- (void) didReceiveNewMessages:(NSArray *)newMessages;

@end

@class IMMessage;
@protocol IMDeliveredMessageDelegate <NSObject>

- (void)willDeliveryMessage:(IMMessage *)message;

- (void)didDeliveredMessage:(IMMessage *)message
                       errorCode:(NSInteger)errorCode
                      error:(NSString *)errorMessage;

@end

@protocol IMCmdMessageDelegate <NSObject>

- (void)didReceiveCommand:(NSArray *)messages;

@end

@protocol  IMContactsChangedDelegate <NSObject>

- (void)didMyContactsChanged;

@end

@class Conversation;
@protocol IMLoadMessageDelegate <NSObject>

- (void)didLoadMessages:(NSArray *)messages
           conversation:(Conversation *)conversation
                hasMore:(BOOL)hasMore;

@end

@protocol IMRecentContactsDelegate <NSObject>

- (void)didLoadRecentContacts:(NSArray *)contacts;

@end

@class User;
@protocol IMUserInfoChangedDelegate <NSObject>

- (void)didUserInfoChanged:(User *)user;

@end

@class Group;
@protocol IMGroupProfileChangedDelegate <NSObject>

- (void)didGroupProfileChanged:(Group *)group;

@end

#endif
