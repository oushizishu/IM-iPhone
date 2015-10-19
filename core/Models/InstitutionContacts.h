//
//  InstitutionContacts.h
//  Pods
//
//  Created by 杨磊 on 15/7/27.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface InstitutionContacts : NSObject

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) int64_t contactId;
@property (nonatomic, assign) IMUserRole contactRole;
@property (nonatomic, assign) int16_t createTime;
@property (nonatomic, copy) NSString *remarkName;
@property (nonatomic, copy) NSString *remarkHeader;

//关注关系字段
@property (nonatomic, assign) IMBlackStatus blackStatus;
@property (nonatomic, assign) IMOriginType originType;
@property (nonatomic, assign) IMFocusType focusType;
@property (nonatomic, assign) IMTinyFocus tinyFoucs;
@property (nonatomic, assign) NSDate *focusTime;
@property (nonatomic, assign) NSDate *fansTime;

@end
