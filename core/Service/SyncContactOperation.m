//
//  SyncContactOperation.m
//  Pods
//
//  Created by 彭碧 on 15/7/21.
//
//

#import "SyncContactOperation.h"
#import "IMEnvironment.h"
#import "BJIMService.h"
#import "GroupMember.h"
@implementation SyncContactOperation
- (void)doOperationOnBackground
{
    User *currentUser = [[IMEnvironment shareInstance] owner];
    
    NSArray *groupList = self.model.groupList;
    NSInteger count = groupList.count;
    
    // 构建 sql 语句。
    NSMutableArray *excutorSQLs = [[NSMutableArray alloc] initWithCapacity:count];
    for (NSInteger index = 0; index < count; ++ index)
    {
        Group *group = [groupList objectAtIndex:index];
        [self.imService.imStorage.groupDao insertOrUpdate:group];
        
        GroupMember *_groupMember = [[GroupMember alloc] init];
        _groupMember.userId = currentUser.userId;
        _groupMember.userRole = currentUser.userRole;
        _groupMember.groupId = group.groupId;
        _groupMember.msgStatus = group.msgStatus;
        _groupMember.canDisband = group.canDisband;
        _groupMember.canLeave = group.canLeave;
        _groupMember.remarkHeader = group.remarkHeader;
        _groupMember.remarkName = group.remarkName;
        _groupMember.pushStatus = group.pushStatus;
        
        if (index == 0) {
            // 第一次调用 LKDBHelper，为了能够自动建表
            [self.imService.imStorage.groupMemberDao insertOrUpdate:_groupMember];
        }
        
        //还是需要先清除掉所有的关系，然后再重新添加
        NSString *sql = [self generatorGroupMmeberSql:_groupMember];
        [excutorSQLs addObject:sql];
    }
    
    // 直接执行sql， 不走缓存层。提升效率
    NSString *deleteGroupSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld", [GroupMember getTableName],currentUser.userId, (long)currentUser.userRole];
    [self.imService.imStorage.dbHelper executeForTransaction:^BOOL(LKDBHelper *helper) {
        
        @try {
            [helper executeSQL:deleteGroupSql arguments:nil];
            NSInteger count = excutorSQLs.count;
            for (NSInteger index = 0; index < count; ++ index) {
                NSString *sql = [excutorSQLs objectAtIndex:index];
                [helper executeSQL:sql arguments:nil];
            }
            return YES;
        }
        @catch (NSException *exception) {
            return NO;
        }
    }];
    
    
    
    // 更新机构联系人
    NSArray *organizationList = self.model.organizationList;
    //    [self executorContacts:organizationList deleteContactRole:eUserRole_Institution];
    [self batchWriteContacts:organizationList contactRole:eUserRole_Institution needRefresh:NO];
    
    // 更新老师联系人
    NSArray *teacherList = self.model.teacherList;
    //    [self executorContacts:teacherList deleteContactRole:eUserRole_Teacher];
    [self batchWriteContacts:teacherList contactRole:eUserRole_Teacher needRefresh:NO];
    
    //更新学生联系人
    NSArray *studentList = self.model.studentList;
    // 分批写入, 这样就不需要长时间占用 FMDB 中 threadLock.
    //    [self executorContacts:studentList deleteContactRole:eUserRole_Student];
    __block BOOL needRefreshUI = NO;
    [self.imService.imStorage.dbHelper executeDB:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"select count(*) from %@ where userId=%lld contactRole=%ld", [self contactsTableName:currentUser], currentUser.userId, (long)eUserRole_Student];
        
        FMResultSet *set = [db executeQuery:sql];
        needRefreshUI = [set longForColumnIndex:0] == 0; // 如果初始化时本地没有数据，中途动态刷新界面
        [set close];
        
    }];
    [self batchWriteContacts:studentList contactRole:eUserRole_Student needRefresh:needRefreshUI];
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyContactChanged];
}

#define SYNC_CONTACT_BATCH_COUNT 30 // 每批次同步联系人，批次数量
- (void)batchWriteContacts:(NSArray *)userList contactRole:(IMUserRole)userRole needRefresh:(BOOL)needRefresh
{
    User *currentUser = [[IMEnvironment shareInstance] owner];
    
    NSString *tableName = [self contactsTableName:currentUser];
    
    NSString *deleteSQL = [NSString stringWithFormat:@"delete from %@ where userId=%lld and contactRole=%ld", tableName, currentUser.userId, (long)userRole];
    
    NSInteger count = [userList count];
    NSInteger batchCount = count/SYNC_CONTACT_BATCH_COUNT;
    if (count % SYNC_CONTACT_BATCH_COUNT > 0) {
        batchCount += 1;
    }
    
    [self.imService.imStorage.dbHelper executeDB:^(FMDatabase *db) {
        [db executeUpdate:deleteSQL withArgumentsInArray:nil];
    }];
    
    __weak typeof(self) weakSelf = self;
    for (NSInteger index = 0; index < batchCount; ++ index) {
        NSInteger start = SYNC_CONTACT_BATCH_COUNT * index;
        NSInteger len = MIN(SYNC_CONTACT_BATCH_COUNT, count - start);
        NSArray *array = [userList objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, len)]];
        
        [self executorContacts:array deleteContactRole:userRole];
        [NSThread sleepForTimeInterval:0.2]; // 让线程等待一会执行, 避免数据量太大的情况下 CPU 占用率持续太高
        
        if (index != 0 && batchCount > 20) { // 加载中途刷新一次界面，避免等待时间过长
            if (index % 20 == 0 && needRefresh) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // 每批次完成执行一次刷新
                    [weakSelf doAfterOperationOnMain];
                });
            }
        }
    }
    
}

- (void)executorContacts:(NSArray *)userList deleteContactRole:(IMUserRole)contactRole
{
    if ([userList count] == 0) return;
    User *currentUser = [IMEnvironment shareInstance].owner;
    NSString *contactTableName = [self contactsTableName:currentUser];
    
    NSInteger count = [userList count];
    __weak typeof(self) weakSelf = self;
    [self.imService.imStorage.dbHelper executeDB:^(FMDatabase *db) {
        
        for (NSInteger index = 0; index < count; ++ index) {
            User *user = [userList objectAtIndex:index];
            [weakSelf.imService.imStorage.userDao insertOrUpdateUser:user];
            
            if (index == 0) {
                [weakSelf.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
            } else {
                NSString *sql = [weakSelf generatorContactSql:user inTable:contactTableName owner:currentUser];
                [db executeUpdate:sql withArgumentsInArray:nil];
            }
            
        }
    }];
}

- (NSString *)generatorUserSql:(User *)user
{
    
    NSString *arguments = [NSString stringWithFormat:@"(%lld,'%@','%@',%ld)",
                           user.userId,
                           user.name == nil ? @"":user.name,
                           user.avatar == nil ? @"":user.avatar,
                           (long)user.userRole];
    NSString *sql = @"replace into %@(userId,name,avatar,userRole) values%@";
    sql = [NSString stringWithFormat:sql, [User getTableName], arguments];
    return sql;
}

- (NSString *)generatorContactSql:(User *)contact inTable:(NSString *)tableName owner:(User *)owner;
{
    NSString *arguments = [NSString stringWithFormat:@"(%ld,'%@',%lld,%lld,%lld,'%@')",
                           (long)contact.userRole,
                           contact.remarkName == nil ? @"":contact.remarkName,
                           owner.userId,
                           contact.userId,
                          (long long)[[NSDate date] timeIntervalSince1970],
                           contact.remarkHeader==nil?@"":contact.remarkHeader];

    NSString *sql = @"replace into %@(contactRole,remarkName,userId,contactId,createTime,remarkHeader) values%@";
    sql = [NSString stringWithFormat:sql, tableName, arguments];
    return sql;
}

- (NSString *)contactsTableName:(User *)owner
{
    if (owner.userRole == eUserRole_Teacher)
    {
        return [TeacherContacts getTableName];
    }
    else if (owner.userRole == eUserRole_Institution)
    {
        return [InstitutionContacts getTableName];
    }
    else if (owner.userRole == eUserRole_Student)
    {
        return [StudentContacts getTableName];
    }
    return nil;
}

- (NSString *)generatorGroupMmeberSql:(GroupMember *)groupMember
{
    NSString *arguments = [NSString stringWithFormat:@"(%d,%d,%d,%lld,%d,%d,%lld,%d,'%@','%@',%lld)",
                            (int)groupMember.msgStatus,
                            (int)groupMember.isAdmin,
                           (int)groupMember.canLeave,
                           groupMember.userId,
                           (int)groupMember.pushStatus,
                           (int)groupMember.userRole,
                           groupMember.createTime,
                           groupMember.canDisband,
                           groupMember.remarkHeader==nil?@"":groupMember.remarkHeader,
                           groupMember.remarkName==nil?@"":groupMember.remarkName,
                           groupMember.groupId];
    NSString *sql = @"replace into %@(msgStatus,isAdmin,canLeave,userId, \
                    pushStatus,userRole,createTime,canDisband,remarkHeader,remarkName,groupId) values%@";
    sql = [NSString stringWithFormat:sql, [GroupMember getTableName],arguments];
    return sql;
}
@end
