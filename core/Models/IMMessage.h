//
//  IMMessage.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "Conversation.h"
#import "IMMessageBody.h"
#import "IMTxtMessageBody.h"
#import "IMImgMessageBody.h"
#import "IMAudioMessageBody.h"
#import "IMEmojiMessageBody.h"
#import "IMLocationMessageBody.h"
#import "IMNotificationMessageBody.h"
#import "IMCardMessageBody.h"
#import "IMCmdMessageBody.h"

@interface IMMessage : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *msgId;
@property (nonatomic, assign) int64_t sender;
@property (nonatomic, assign) IMUserRole senderRole;
@property (nonatomic, assign) int64_t receiver;
@property (nonatomic, assign) IMUserRole receiverRole;
@property (nonatomic, copy) NSDictionary *ext;
@property (nonatomic, assign) int64_t createAt;
@property (nonatomic, assign) IMChatType chat_t;
@property (nonatomic, assign) IMMessageType msg_t;
@property (nonatomic, assign) IMMessageStatus status;
@property (nonatomic, assign) NSInteger read;
@property (nonatomic, assign) NSInteger played;
@property (nonatomic, copy) NSString *sign;

@property (nonatomic, assign) NSInteger conversationId;
@property (nonatomic, strong) IMMessageBody *messageBody;

@end
