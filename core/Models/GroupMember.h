//
//  GroupMember.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import "User.h"

@interface GroupMember : NSObject

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) IMUserRole userRole;
@property (nonatomic, assign) int64_t groupId;
@property (nonatomic, assign) NSInteger isAdmin;
@property (nonatomic, assign) int64_t createTime;

@property (nonatomic, assign) IMGroupMsgStatus msgStatus;
@property (nonatomic, assign) BOOL canLeave;//是否能退出
@property (nonatomic, assign) BOOL canDisband;//是否能解散
@property (nonatomic, assign) NSInteger pushStatus;

@property (nonatomic, copy) NSString *remarkName; //备注名
@property (nonatomic, copy) NSString *remarkHeader; //备注首字母

@end
