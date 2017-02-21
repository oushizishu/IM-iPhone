//
//  MemberProfile.h
//  Pods
//
//  Created by 辛亚鹏 on 2017/2/17.
//
//

#import <Mantle/Mantle.h>
#import "BJIMConstants.h"

@interface MemberProfile : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) int64_t userNumber;
@property (nonatomic, assign) int64_t groupId;
@property (nonatomic, assign) IMUserRole userRole;

@property (nonatomic, assign) BOOL isForbid;   // yes:禁言  no:正常
@property (nonatomic, assign) BOOL isAdmin;
@property (nonatomic, assign) BOOL isMember;  //是否是本群的成员

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *avatar;


@end
