//
//  SocialContacts.h
//  Pods
//
//  Created by 杨磊 on 15/10/21.
//
//

#import "MTLModel.h"
#import "BJIMConstants.h"

@interface SocialContacts : MTLModel

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) IMUserRole userRole;
@property (nonatomic, assign) int64_t contactId;
@property (nonatomic, assign) int64_t contactRole;

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
