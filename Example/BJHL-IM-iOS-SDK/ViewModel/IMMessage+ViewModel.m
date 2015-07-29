//
//  IMMessage+ViewModel.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "IMMessage+ViewModel.h"
#import <IMEnvironment.h>
#import <IMTxtMessageBody.h>
#import <IMImgMessageBody.h>
#import <IMAudioMessageBody.h>
#import <IMEmojiMessageBody.h>
#import <IMCardMessageBody.h>
#import <BJFileManagerTool.h>
#import <IMMessage+DB.h>

#import "BJChatAudioPlayerHelper.h"
#import "MyFacialView.h"


@implementation IMMessage (ViewModel)

- (BOOL)isMySend;    //是否是自己发送的
{
    if (self.sender == [IMEnvironment shareInstance].owner.userId &&
        self.senderRole == [IMEnvironment shareInstance].owner.userRole) {
        return YES;
    }
    return NO;
}

- (BOOL)isRead;      //是否已读
{
    return self.read;
}

- (IMMessageStatus)deliveryStatus;
{
    return self.status;
}

- (NSURL *)headImageURL;
{
    User *senderUser = [self getSenderUser];
    return [NSURL URLWithString:senderUser.avatar];
}

- (NSAttributedString *)nickNameAttri
{
    NSString *typeName = @"";
    UIColor *typeColor = [UIColor clearColor];
    switch (self.senderRole) {
        case eUserRole_Teacher: {
            typeColor = BJChatColorFromRGB(0xffb545);
            typeName = @"老师";
            break;
        }
        case eUserRole_Student: {
            typeColor = BJChatColorFromRGB(0x94ace4);
            typeName = @"学生";
            break;
        }
        case eUserRole_Institution: {
            typeColor = BJChatColorFromRGB(0x94c678);
            typeName = @"机构客服";
            break;
        }
        case eUserRole_Kefu: {
            typeColor = BJChatColorFromRGB(0x94c678);
            typeName = @"学生";
            break;
        }
        case eUserRole_Anonymous: {
            typeColor = BJChatColorFromRGB(0x94ace4);
            typeName = @"访客";
            break;
        }
    }
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@",typeName,self.nickName]];
    [attStr addAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSBackgroundColorAttributeName:typeColor} range:NSMakeRange(0, typeName.length)];
    return [attStr copy];
}

- (NSString *)nickName;
{
    User *senderUser = [self getSenderUser];
    return senderUser.name;
}

- (NSString *)content;//text
{
    if ([self.messageBody isKindOfClass:[IMTxtMessageBody class]]) {
        IMTxtMessageBody *body = (IMTxtMessageBody *)self.messageBody;
        return body.content;
    }
    
    NSAssert(0, @"类型不是IMTxtMessageBody，请检查");
    return nil;
}

#pragma mark - image
- (IMImgMessageBody*)imgMessageBody;
{
    if ([self.messageBody isKindOfClass:[IMImgMessageBody class]]) {
        IMImgMessageBody *body = (IMImgMessageBody *)self.messageBody;
        return body;
    }
    NSAssert(0, @"类型不是IMImgMessageBody，请检查");
    return nil;
}
- (CGSize)imageSize
{
    return CGSizeMake([self imgMessageBody].width, [self imgMessageBody].height);
}

- (NSURL *)imageURL
{
    IMImgMessageBody *imgMessage = [self imgMessageBody];
    if (imgMessage.file.length>0) {
        if ([BJFileManagerTool isFileExisted:nil path:imgMessage.file]) {
            return [NSURL fileURLWithPath:imgMessage.file];
        }
    }
    return [NSURL URLWithString:[self imgMessageBody].url];
}

#pragma mark - EMOJI
- (IMEmojiMessageBody*)emojiMessageBody;
{
    if ([self.messageBody isKindOfClass:[IMEmojiMessageBody class]]) {
        IMEmojiMessageBody *body = (IMEmojiMessageBody *)self.messageBody;
        return body;
    }
    NSAssert(0, @"类型不是IMEmojiMessageBody，请检查");
    return nil;
}

- (CGSize)emojiSize
{
    return CGSizeMake(60, 60);
}

- (NSURL *)emojiImageURL;
{
    NSString *gifLocal = [MyFacialView imageNamedWithEmoji:[self emojiMessageBody].name];
    NSURL *gifURL = nil;
    if (gifLocal.length>0) {
        gifURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[gifLocal substringToIndex:gifLocal.length - gifLocal.pathExtension.length - 1] ofType:gifLocal.pathExtension]];
    }else
    {
        @TODO("远程图片下载");
    }
    return gifURL;
}

#pragma mark - Audio
- (IMAudioMessageBody*)audioMessageBody;
{
    if ([self.messageBody isKindOfClass:[IMAudioMessageBody class]]) {
        IMAudioMessageBody *body = (IMAudioMessageBody *)self.messageBody;
        return body;
    }
    NSAssert(0, @"类型不是IMAudioMessageBody，请检查");
    return nil;
}
//audio
- (NSURL *)audioURL;
{
    IMAudioMessageBody *audioMessage = [self audioMessageBody];
    if (audioMessage.file.length>0) {
        if ([BJFileManagerTool isFileExisted:nil path:audioMessage.file]) {
            return [NSURL fileURLWithPath:audioMessage.file];
        }
    }
    return [NSURL URLWithString:[self audioMessageBody].url];
}

- (NSInteger)time;
{
    return [self audioMessageBody].length;
}
- (BOOL)isPlayed;
{
    return self.played;
}

- (BOOL)isPlaying
{
    return [[BJChatAudioPlayerHelper sharedInstance] isPlayerWithMessage:self];
}

#pragma mark - card
- (IMCardMessageBody *)cardMessageBody;
{
    if ([self.messageBody isKindOfClass:[IMCardMessageBody class]]) {
        IMCardMessageBody *body = (IMCardMessageBody *)self.messageBody;
        return body;
    }
    NSAssert(0, @"类型不是IMCardMessageBody，请检查");
    return nil;
}
- (NSString *)cardTitle;
{
    return [self cardMessageBody].title;
}

- (NSString *)cardContent;
{
    return [self cardMessageBody].content;
}

- (NSString *)cardUrl;
{
    return [self cardMessageBody].url;
}

- (NSString *)cardThumb;
{
    return [self cardMessageBody].thumb;
}

#pragma mark - gossip 通知和cmd显示消息
- (NSString *)gossipText;
{
    IMMessageBody *body = self.messageBody;
    @TODO("请添加这块的小道消息代码");
    return @"请添加这块的小道消息代码";
}

@end
