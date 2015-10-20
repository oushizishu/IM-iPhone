//
//  NewFansContactDao.m
//  Pods
//
//  Created by 杨磊 on 15/10/20.
//
//

#import "NewFansContactDao.h"
#import "NewFansContact.h"

@implementation NewFansContactDao

- (NSInteger)queryNewFansCount:(User *)owner
{
    __block NSInteger count = 0;
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"select count(*) from %@ where userId=%lld and userRole=%ld", [NewFansContact getTableName], owner.userId, (long)owner.userRole];
        FMResultSet *set = [db executeQuery:sql];
        if ([set next]) {
            count = [set longForColumnIndex:0];
        }
        [set close];
    }];
    
    return count;
}

- (void)addNewFans:(User *)fans owner:(User *)owner
{
    NewFansContact *contact = [[NewFansContact alloc] init];
    contact.userId = owner.userId;
    contact.userRole = owner.userRole;
    contact.fansId = fans.userId;
    contact.fansRole = fans.userRole;
    
    [self.dbHelper insertToDB:contact callback:nil];
}

- (void)deleteNewFans:(User *)fans owner:(User *)owner
{
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld \
                               and fansId=%lld and fansRole=%ld", [NewFansContact getTableName],
                                owner.userId, (long)owner.userRole,
                               fans.userId, (long)fans.userRole];
        [db executeUpdate:deleteSql];
    }];
}

- (void)deleteAllNewFans:(User *)owner
{
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld",
                               [NewFansContact getTableName],
                               owner.userId, (long)owner.userRole];
        [db executeUpdate:deleteSql];
    }];
}

@end
