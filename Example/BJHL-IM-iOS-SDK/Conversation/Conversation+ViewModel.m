//
//  Conversation+ViewModel.m
//  BJEducation_Institution
//
//  Created by Randy on 15/7/31.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#import "Conversation+ViewModel.h"
#import <Conversation+DB.h>
#import <IMMessage.h>
#import "BJChatDraft.h"
#import "IMMessage+ViewModel.h"

#import "User+ViewModel.h"
#import "Group+ViewModel.h"

@implementation Conversation (ViewModel)
- (NSString *)getContactName;
{
    if (self.chat_t == eChatType_Chat) {
        return [self.chatToUser getContactName];
    }
    else if (self.chat_t == eChatType_GroupChat)
    {
        return [self.chatToGroup getContactName];
    }
    else
    {
        return @"";
    }
}

- (NSString *)getContactAvatar;
{
    if (self.chat_t == eChatType_Chat) {
        return [self.chatToUser getContactAvatar];
    }
    else if (self.chat_t == eChatType_GroupChat)
    {
        return [self.chatToGroup getContactAvatar];
    }
    else
    {
        return @"";
    }
}

- (BJContactType)getContactType;
{
    if (self.chat_t == eChatType_Chat) {
        return [self.chatToUser getContactType];
    }
    else if (self.chat_t == eChatType_GroupChat)
    {
        return [self.chatToGroup getContactType];
    }
    return BJContact_Unkonwn;
}

- (long long)getContactId;
{
    return self.toId;
}

- (long long)getContactTime;
{
    BJChatDraft *draft = [BJChatDraft conversationDraftForUserId:self.toId andUserRole:self.toRole];
    if (draft) {
        return [draft.updateTime timeIntervalSince1970];
    }
    return self.lastMessage.createAt;;
}

- (NSAttributedString *)getContactContentAttr;
{
    BJChatDraft *draft = [BJChatDraft conversationDraftForUserId:self.toId andUserRole:self.toRole];
    NSMutableAttributedString *showAMsg = nil;

    if (draft) {
//        NSString *showMsg = [NSString stringWithFormat:@"[草稿] %@", draft.content];
//        showAMsg = [[NSMutableAttributedString alloc] initWithString:showMsg attributes:@{NSFontAttributeName : APP_FONT_SIZE_14}];
//        [showAMsg addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0xB80000) range:[showMsg rangeOfString:@"[草稿]"]];
//        return [showAMsg copy];
    }
    IMMessage *message = self.lastMessage;
    if (message) {
        NSString *showMsg = @"";
        switch (self.lastMessage.msg_t) {
            case eMessageType_TXT: {
                showMsg = message.content;
                break;
            }
            case eMessageType_IMG: {
                showMsg = @"[图片]";
                break;
            }
            case eMessageType_AUDIO: {
                showMsg = @"[语音]";
                break;
            }
            case eMessageType_LOCATION: {
                showMsg = @"[位置]";
                break;
            }
            case eMessageType_NOTIFICATION: {
                showMsg = message.gossipText;
                break;
            }
            case eMessageType_CARD: {
                showMsg = [NSString stringWithFormat:@"[%@]",message.cardTitle];
                break;
            }
            case eMessageType_EMOJI: {
                showMsg = [NSString stringWithFormat:@"[%@]",message.emojiName];
                break;
            }
            case eMessageType_CMD: {
                showMsg = @"[消息]";
                break;
            }
            default: {
                break;
            }
        }
        if (showMsg.length>0) {
            return [[NSMutableAttributedString alloc] initWithString:showMsg attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14]}];
        }
    }
    return nil;
}

- (NSString *)getContactHeader;
{
    if (self.chat_t == eChatType_Chat) {
        return [self.chatToUser getContactHeader];
    }
    else if (self.chat_t == eChatType_GroupChat)
    {
        return [self.chatToGroup getContactHeader];
    }
    else
    {
        return @"";
    }
}

@end
