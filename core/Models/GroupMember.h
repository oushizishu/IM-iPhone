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
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) int64_t createTime;
@property (nonatomic, assign) NSInteger msgStatus;
@property (nonatomic, copy) NSString *remarkName; //备注名
@property (nonatomic, copy) NSString *remarkHeader; //备注首字母

@property (nonatomic, strong) User *member;

@end
