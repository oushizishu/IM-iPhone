//
//  NewFansContactDao.h
//  Pods
//
//  Created by 杨磊 on 15/10/20.
//
//

#import "IMBaseDao.h"
#import "User.h"

@interface NewFansContactDao : IMBaseDao

- (NSInteger)queryNewFansCount:(User *)owner;

- (void)addNewFans:(User *)fans owner:(User *)owner;
- (void)deleteNewFans:(User *)fans owner:(User *)owner;
- (void)deleteAllNewFans:(User *)owner;

@end
