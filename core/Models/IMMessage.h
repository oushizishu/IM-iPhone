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

@interface IMMessage : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) double_t msgId;
@property (nonatomic, assign) int64_t sender;
@property (nonatomic, assign) IMUserRole senderRole;
@property (nonatomic, assign) int64_t receiver;
@property (nonatomic, assign) IMUserRole receiverRole;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSDictionary *ext;
@property (nonatomic, assign) int64_t createAt;
@property (nonatomic, assign) IMChatType chat_t;
@property (nonatomic, assign) IMMessageType msg_t;
@property (nonatomic, assign) IMMessageStatus status;
@property (nonatomic, assign) NSInteger read;
@property (nonatomic, assign) NSInteger played;
@property (nonatomic, copy) NSString *sign;
@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, strong) IMMessageBody *messageBody;

@end