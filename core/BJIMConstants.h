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
#define BJIM_VERSION_10     @"1.0.0"      // 4.0 之前的版本号都为 1.0；
#define BJIM_VERSION_41     @"4.1.0"    // 去除完关注体系；拆分数据库
#define BJIM_VERSION_42     @"4.2.0"    // 清除关注历史数据
#define BJIM_VERSION_43     @"4.3.0"    // bugfix
#define BJIM_VERSTION       BJIM_VERSION_43

#import <LKDBHelper/NSObject+LKModel.h>
#import <Mantle/Mantle.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDLegacyMacros.h>

#pragma mark - 接口返回成功码
#define RESULT_CODE_SUCC 0

#pragma mark - 自定义角色id
typedef NS_ENUM(NSInteger, IMSDKUSer) {
    USER_SYSTEM_SECRETARY = 100000100, // 系统小秘书
    USER_CUSTOM_WAITER    =   100000110, // 客服
};



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

#pragma mark - 用户关系
typedef NS_ENUM(NSInteger, IMUserRelation)
{
    eUserRelation_normal = 0, // 正常关系
    eUserRelation_black_passive = 1, //被拉黑
    eUserRelation_black_active = 2,// 主动拉黑
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

#pragma mark - 卡片消息类型 type 值.
typedef NS_ENUM(NSInteger, IMCardMessageType)
{
    /*! @brief  班课类型*/
    eIMCardMessageTypeClassCourse = 3,
    /*! @brief 教师详情*/
    eIMCardMessageTypeTeacherDetail = 1,
    /*! @brief 机构详情*/
    eIMCardMessageTypeOrgDetail = 2,
    /*! @brief 机构黑板报*/
    eIMCardMessageTypeOrgBlackBoard = 4,
    /*! @brief 机构优惠劵*/
    eIMCardMessageTypeOrgCoupon = 5,
    /*! @brief 老师优惠劵*/
    eIMCardMessageTypeTeacherCoupon = 6,
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
//消息提醒状态
typedef NS_ENUM(NSInteger, IMGroupMsgStatus)
{
    eGroupMsg_All = 0, //提示所有消息;
    eGroupMsg_OnlyTeacher = 1, //只提示老师消息
    eGroupMsg_None = 2, //不提示
};

// 群消息面da扰状态
typedef NS_ENUM(NSInteger, IMGroupPushStatus)
{
    eGroupPushStatus_close = 0,
    eGroupPushStatus_open = 1
};


//错误类型
typedef NS_ENUM(NSInteger, IMErrorType) {
    eError_msgError = -3,//返回reason错误
    eError_paramsError = -2,
    eError_noLogin = -1,
    eError_suc = 0,
    eError_token_invalid = 510005, //token 失效
};

#pragma mark - 来源类型
typedef NS_ENUM(NSInteger, IMOriginType) {
    eIMOriginType_Order = 1, //订单
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

@protocol IMNewGRoupNoticeDelegate <NSObject>

- (void)didNewGroupNotice;

@end

@class Conversation;
@protocol IMLoadMessageDelegate <NSObject>

- (void)didLoadMessages:(NSArray *)messages
           conversation:(Conversation *)conversation
                hasMore:(BOOL)hasMore;

- (void)didPreLoadMessages:(NSArray *)preMessages
              conversation:(Conversation *)conversation;
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

@protocol IMDisconnectionDelegate <NSObject>

- (void)didDisconnectionServer:(IMErrorType)code errMsg:(NSString *)errorMessage;

@end

@protocol IMUnReadNumChangedDelegate <NSObject>

- (void)didUnReadNumChanged:(NSInteger)unReadNum otherUnReadNum:(NSInteger)otherUnReadNum;

@end

/**
 *  主动处理登陆退出回调
 */
@protocol IMLoginLogoutDelegate <NSObject>

- (void)didIMManagerLoginFinish;
- (void)didIMManagerLogoutFinish;

@end

@class GroupMemberListData;
@class GroupMember;
@protocol IMGroupManagerResultDelegate <NSObject>
@optional
- (void)onGetGroupProfileResult:(NSError *)error groupId:(int64_t)groupId group:(Group *)group;
- (void)onGetGroupMemberResult:(NSError *)error members:(GroupMemberListData *)memberList page:(NSInteger)page groupId:(int64_t)groupId;
- (void)onGetGroupMemberResult:(NSError *)error members:(GroupMemberListData *)memberList;
- (void)onGetGroupMemberResult:(NSError *)error members:(GroupMemberListData *)memberList userRole:(IMUserRole)userRole page:(NSInteger)page groupId:(int64_t)groupId;
- (void)onLeaveGroupResult:(NSError *)error groupId:(int64_t)groupId;
- (void)onDisbandGroupResult:(NSError *)error groupId:(int64_t)groupId;
- (void)onChangeGroupNameResult:(NSError *)error newName:(NSString *)newName groupId:(int64_t)groupId;
- (void)onChangeMsgStatusResult:(NSError *)error msgStatus:(IMGroupMsgStatus)status groupId:(int64_t)groupId;
- (void)onChangePushStatusResult:(NSError *)error pushStatus:(IMGroupPushStatus)stauts groupId:(int64_t)groupId;
@end

#endif
