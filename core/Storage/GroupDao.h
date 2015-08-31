//
//  GroupDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/31.
//
//

#import "IMBaseDao.h"
#import "Group.h"

@interface GroupDao : IMBaseDao

- (Group *)load:(int64_t)groupId;

- (void)insertOrUpdate:(Group *)group;

- (void)deleteGroup:(int64_t)groupId;
//- (void)deleteAll:(User *)user;
@end
