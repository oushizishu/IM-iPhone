//
//  IMNotificationMessageBody.h
//  Pods
//
//  Created by 杨磊 on 15/7/29.
//
//

#import "IMTxtMessageBody.h"

@interface IMNotificationMessageBody : IMMessageBody
@property (nonatomic, assign) TxtMessageContentType type;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *action;

@end
