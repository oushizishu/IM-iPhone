//
//  UserDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "IMBaseDao.h"

#import "User.h"

@interface UserDao : IMBaseDao

- (User *)loadUser:(int64_t)userId  role:(IMUserRole)userRole;
- (User *)loadUserAndMarkName:(int64_t)userId role:(IMUserRole)userRole owner:(User *)owner;
- (void)insertOrUpdateUser:(User *)user;

@end
