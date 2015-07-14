//
//  IMTxtMessageBody.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMMessageBody.h"

typedef NS_ENUM(NSInteger, TxtMessageContentType)
{
    eTxtMessageContentType_NORMAL = 0,
    eTxtMessageContentType_RICH_TXT = 1
};

@interface IMTxtMessageBody : IMMessageBody

@property (nonatomic, assign) TxtMessageContentType type;
@property (nonatomic, copy) NSString *content;

@end
