//
//  ConversationTableViewCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by 杨磊 on 15/7/20.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJConversationTableViewCell.h"

#import <BJHL-IM-iOS-SDK/Conversation+DB.h>
#import <BJHL-IM-iOS-SDK/IMMessage.h>

#import <BJHL-Kit-iOS/BJHL-Kit-iOS.h>
#import <BJHL-Foundation-iOS/BJHL-Foundation-iOS.h>

@interface BJConversationTableViewCell()

@property (nonatomic, strong) UILabel *name;
@property (nonatomic, strong) UILabel *unreadNum;
@property (nonatomic, strong) UILabel *message;

@end

@implementation BJConversationTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.name = [[UILabel alloc] init];
        self.name.textColor = [UIColor blackColor];
        self.unreadNum = [[UILabel alloc] init];
        self.unreadNum.textColor = [UIColor blackColor];
        self.message = [[UILabel alloc] init];
        self.message.textColor = [UIColor blackColor];
        
        [self addSubview:self.name];
        [self addSubview:self.unreadNum];
        [self addSubview:self.message];
    }
    return self;
}

- (void)layoutSubviews
{

    self.name.frame = CGRectMake(10,  5, 100, self.bjck_current_h - 5);
    self.unreadNum.frame = CGRectMake(self.name.bjck_current_x_w + 5, self.name.bjck_current_y, 50, self.bjck_current_h  - 5);
    self.message.frame = CGRectMake(self.unreadNum.bjck_current_x_w, self.unreadNum.bjck_current_y, self.bjck_current_w - self.unreadNum.bjck_current_x_w- 10, self.unreadNum.bjck_current_h);

    if (self.conversation.chat_t == eChatType_Chat)
    {
        self.name.text = self.conversation.chatToUser.name;
    }
    else
    {
        self.name.text = self.conversation.chatToGroup.groupName;
    }
    
    NSInteger unreadNum =  self.conversation.unReadNum;
    self.unreadNum.text = [NSString stringWithFormat:@"未读 %ld", unreadNum];
    
    IMMessageBody *messageBody = [[self.conversation lastMessage] messageBody];
    if ([self.conversation lastMessage].msg_t == eMessageType_TXT)
    {
        IMTxtMessageBody *body = (IMTxtMessageBody *)messageBody;
        self.message.text = body.content;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
