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
#import "IMEnvironment.h"
#import "User.h"
#import "Conversation.h"
#import "Group.h"
#import "IMMessage.h"

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
    eMessageTYpe_EMOJI = 6,
    eMessageTYpe_CMD = 7,
};

#pragma mark - 消息状态
typedef NS_ENUM(NSInteger, IMMessageStatus)
{
    eMessageState_init = 0,
    eMessageState_Sending = 1,
    eMessageState_Send_Succ = 2,
    eMessageState_Send_Fail = 3,
};

#pragma mark - 聊天类型
typedef NS_ENUM(NSInteger, IMChatType) {
    eChatType_Chat = 0, // 单聊
    eChatType_GroupChat = 1 // 群聊
};

#endif
