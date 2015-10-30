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
#import "SocialContacts.h"

@implementation SyncContactOperation
- (void)doOperationOnBackground
{
    User *currentUser = [[IMEnvironment shareInstance] owner];
    
    NSArray *groupList = self.model.groupList;
    NSInteger count = groupList.count;
    
    // 构建 sql 语句。
    NSMutableArray *excutorSQLs = [[NSMutableArray alloc] initWithCapacity:count];
    NSMutableArray *groupArguments = [[NSMutableArray alloc] initWithCapacity:count];
    for (NSInteger index = 0; index < count; ++ index)
    {
        Group *group = [groupList objectAtIndex:index];
        [self.imService.imStorage.groupDao insertOrUpdate:group];
        
        if (index == 0) {
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
            _groupMember.isAdmin = group.isAdmin;
            _groupMember.joinTime = group.joinTime;
            
            // 第一次调用 LKDBHelper，为了能够自动建表
            [self.imService.imStorage.groupMemberDao insertOrUpdate:_groupMember];
        }
        
        //还是需要先清除掉所有的关系，然后再重新添加
        NSString *sql = [self generatorGroupMmeberSql];
        NSArray *arguments = @[@(group.msgStatus),
                               @(group.isAdmin),
                               @(group.canLeave),
                               @(currentUser.userId),
                               @(group.pushStatus),
                               @(currentUser.userRole),
                               @(group.createTime),
                               @(group.canDisband),
                               group.remarkHeader==nil?@"":group.remarkHeader,
                               group.remarkName==nil?@"":group.remarkName,
                               @(group.groupId),
                               group.joinTime==nil?[NSDate date]:group.joinTime];
        [groupArguments addObject:arguments];
       
        [excutorSQLs addObject:sql];
    }
    
    // 直接执行sql， 不走缓存层。提升效率
    NSString *deleteGroupSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld", [GroupMember getTableName],currentUser.userId, (long)currentUser.userRole];
    [self.imService.imStorage.dbHelper executeDB:^(FMDatabase *db) {
        [db executeUpdate:deleteGroupSql];
        NSInteger count = excutorSQLs.count;
        for (NSInteger index = 0; index < count; ++ index) {
            NSString *sql = [excutorSQLs objectAtIndex:index];
            [db executeUpdate:sql withArgumentsInArray:[groupArguments objectAtIndex:index]];
        }
    }];
    
    NSString *tableName = [self contactsTableName:currentUser];
    
    // 更新机构联系人
    NSArray *organizationList = self.model.organizationList;
    [self batchWriteContacts:organizationList contactRole:eUserRole_Institution needRefresh:NO];
    
    // 更新老师联系人
    NSArray *teacherList = self.model.teacherList;
    [self batchWriteContacts:teacherList contactRole:eUserRole_Teacher needRefresh:NO];
    
    //更新学生联系人
    NSArray *studentList = self.model.studentList;
    // 分批写入, 这样就不需要长时间占用 FMDB 中 threadLock.
    __block BOOL needRefreshUI = NO;
    [self.imService.imStorage.dbHelper executeDB:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"select count(*) from %@ where userId=%lld and contactRole=%ld", tableName, currentUser.userId, (long)eUserRole_Student];
        
        FMResultSet *set = [db executeQuery:sql];
        if ([set next]) {
            needRefreshUI = [set longForColumnIndex:0] == 0; // 如果初始化时本地没有数据，中途动态刷新界面
        }
        [set close];
        
    }];
    [self batchWriteContacts:studentList contactRole:eUserRole_Student needRefresh:needRefreshUI];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf doAfterOperationOnMain];
    });
    
    //更新我的关注
    [self.imService.imStorage.socialContactsDao clearAll:currentUser];
    NSArray *focusUserList = self.model.focusList;
    count = [focusUserList count];
    for (NSInteger index = 0; index < count; ++ index) {
        User *user = [focusUserList objectAtIndex:index];
        [self.imService.imStorage.userDao insertOrUpdateUser:user];
        [self.imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:currentUser];
    }
    
    
    NSArray *fansUserList = self.model.fansList;
    count = [fansUserList count];
    for (NSInteger index = 0; index < count; ++ index) {
        User *user = [fansUserList objectAtIndex:index];
        [self.imService.imStorage.userDao insertOrUpdateUser:user];
        [self.imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:currentUser];
    }
    
    NSArray *blackList = self.model.blackList;
    count = [blackList count];
    for (NSInteger index = 0; index < count; ++ index) {
        User *user = [blackList objectAtIndex:index];
        [self.imService.imStorage.userDao insertOrUpdateUser:user];
        [self.imService.imStorage.socialContactsDao insertOrUpdate:user withOwner:currentUser];
    }
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
        
        [self executorContacts:array];
        [NSThread sleepForTimeInterval:0.2]; // 让线程等待一会执行, 避免数据量太大的情况下 CPU 占用率持续太高
        
        if (index != 0 && batchCount > 20) { // 加载中途刷新一次界面，避免等待时间过长
            if ((index == 2 || index % 20 == 0) && needRefresh) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // 每批次完成执行一次刷新
                    [weakSelf doAfterOperationOnMain];
                });
            }
        }
    }
    
}

- (void)executorContacts:(NSArray *)userList
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
                
                NSArray *arguments = @[@(user.userRole),
                                       user.remarkName==nil?@"":user.remarkName,
                                       @(currentUser.userId),
                                       @(user.userId),
                                       @((long long)[[NSDate date] timeIntervalSince1970]),
                                       user.remarkHeader==nil?@"":user.remarkHeader,
                                       ];
                
                [db executeUpdate:sql withArgumentsInArray:arguments];
            }
            
        }
    }];
}

- (NSString *)generatorContactSql:(User *)contact inTable:(NSString *)tableName owner:(User *)owner;
{
    NSString *sql = @"replace into %@(contactRole,remarkName,userId,contactId,createTime,remarkHeader) \
                               values(?,?,?,?,?,?)";
    sql = [NSString stringWithFormat:sql, tableName];
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

- (NSString *)generatorGroupMmeberSql
{
    NSString *sql = @"replace into %@(msgStatus,isAdmin,canLeave,userId, \
                    pushStatus,userRole,createTime,canDisband,remarkHeader,remarkName,groupId, joinTime) values(?,?,?,?,?,?,?,?,?,?,?, ?)";
    sql = [NSString stringWithFormat:sql, [GroupMember getTableName]];
    return sql;
}

- (NSString *)generatorDeleteFocusSql:(User *)owner
{
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and focusType=%ld or focusType=%ld",[SocialContacts getTableName], owner.userId, (long)eIMFocusType_Active, (long)eIMFocusType_Both];
    return sql;
}

- (NSString *)generatorDeleteFansSql:(User *)owner
{
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and focusType=%ld or focusType=%ld",[SocialContacts getTableName], owner.userId, (long)eIMFocusType_Passive, (long)eIMFocusType_Both];
    return sql;
}

- (NSString *)generatorDeleteBlackSql:(User *)owner
{
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where userId=%lld blackStatus=%ld",[SocialContacts getTableName], owner.userId, (long)eIMBlackStatus_Active];
    return sql;
}
@end
