//
//  FreshFansContactDao.h
//  Pods
//
//  Created by 杨磊 on 15/10/20.
//
//

#import "IMBaseDao.h"
#import "User.h"

@interface FreshFansContactDao : IMBaseDao

- (NSInteger)queryFreshFansCount:(User *)owner;

- (void)addFreshFans:(User *)fans owner:(User *)owner;
- (void)deleteFreshFans:(User *)fans owner:(User *)owner;
- (void)deleteAllFreshFans:(User *)owner;

@end
