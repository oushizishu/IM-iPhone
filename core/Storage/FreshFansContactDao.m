//
//  FreshFansContactDao.m
//  Pods
//
//  Created by 杨磊 on 15/10/20.
//
//

#import "FreshFansContactDao.h"
#import "FreshFansContact.h"

@implementation FreshFansContactDao

- (NSInteger)queryFreshFansCount:(User *)owner
{
    __block NSInteger count = 0;
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"select count(*) from %@ where userId=%lld and userRole=%ld", [FreshFansContact getTableName], owner.userId, (long)owner.userRole];
        FMResultSet *set = [db executeQuery:sql];
        if ([set next]) {
            count = [set longForColumnIndex:0];
        }
        [set close];
    }];
    
    return count;
}

- (void)addFreshFans:(User *)fans owner:(User *)owner
{
    FreshFansContact *contact = [[FreshFansContact alloc] init];
    contact.userId = owner.userId;
    contact.userRole = owner.userRole;
    contact.fansId = fans.userId;
    contact.fansRole = fans.userRole;
    
    [self.dbHelper insertToDB:contact callback:nil];
}

- (void)deleteFreshFans:(User *)fans owner:(User *)owner
{
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld \
                               and fansId=%lld and fansRole=%ld", [FreshFansContact getTableName],
                                owner.userId, (long)owner.userRole,
                               fans.userId, (long)fans.userRole];
        [db executeUpdate:deleteSql];
    }];
}

- (void)deleteAllFreshFans:(User *)owner
{
    [self.dbHelper executeDB:^(FMDatabase *db) {
        NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld",
                               [FreshFansContact getTableName],
                               owner.userId, (long)owner.userRole];
        [db executeUpdate:deleteSql];
    }];
}

@end
