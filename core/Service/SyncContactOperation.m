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

#import "ContactsDao.h"
#import "Contacts.h"

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
    
    // 更新群的会话免打扰状态
    NSString *sql = @"update CONVERSATION set relation=2  where toId in (select groupId from Conversation inner join GROUPMEMBER on CONVERSATION.toId=GROUPMEMBER.groupId where  CONVERSATION.chat_t=1 and pushStatus=1)";
    
    [self.imService.imStorage.dbHelper executeDB:^(FMDatabase *db) {
        BOOL res = [db executeUpdate:sql];
        [self.imService.imStorage.conversationDao clear];
    }];
    
    // 直接执行sql， 不走缓存层。提升效率
    NSString *deleteGroupSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld", [GroupMember getTableName],currentUser.userId, (long)currentUser.userRole];
    [self.imService.imStorage.dbHelperInfo executeDB:^(FMDatabase *db) {
        [db executeUpdate:deleteGroupSql];
        NSInteger count = excutorSQLs.count;
        for (NSInteger index = 0; index < count; ++ index) {
            NSString *sql = [excutorSQLs objectAtIndex:index];
            [db executeUpdate:sql withArgumentsInArray:[groupArguments objectAtIndex:index]];
        }
    }];
    
    NSString *tableName = [Contacts getTableName];//[self contactsTableName:currentUser];
    
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
    [self.imService.imStorage.dbHelperInfo executeDB:^(FMDatabase *db) {
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

    // 黑名单
    NSArray *blackList = self.model.blackList;
    [self.imService.imStorage.contactsDao removeAllBlack:currentUser];
    [self executorContacts:blackList relation:eUserRelation_black_active];
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyContactChanged];
}

#define SYNC_CONTACT_BATCH_COUNT 30 // 每批次同步联系人，批次数量
- (void)batchWriteContacts:(NSArray *)userList contactRole:(IMUserRole)userRole needRefresh:(BOOL)needRefresh
{
    User *currentUser = [[IMEnvironment shareInstance] owner];
    
    NSString *tableName = [Contacts getTableName];//[self contactsTableName:currentUser];
    
    NSString *deleteSQL = [NSString stringWithFormat:@"delete from %@ where userId=%lld and contactRole=%ld", tableName, currentUser.userId, (long)userRole];
    
    NSInteger count = [userList count];
    NSInteger batchCount = count/SYNC_CONTACT_BATCH_COUNT;
    if (count % SYNC_CONTACT_BATCH_COUNT > 0) {
        batchCount += 1;
    }
    
    [self.imService.imStorage.dbHelperInfo executeDB:^(FMDatabase *db) {
        [db executeUpdate:deleteSQL withArgumentsInArray:nil];
    }];
    
    __weak typeof(self) weakSelf = self;
    for (NSInteger index = 0; index < batchCount; ++ index) {
        NSInteger start = SYNC_CONTACT_BATCH_COUNT * index;
        NSInteger len = MIN(SYNC_CONTACT_BATCH_COUNT, count - start);
        NSArray *array = [userList objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, len)]];
        
        [self executorContacts:array relation:eUserRelation_normal];
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

- (void)executorContacts:(NSArray *)userList relation:(IMUserRelation)relation
{
    if ([userList count] == 0) return;
    User *currentUser = [IMEnvironment shareInstance].owner;
    NSString *contactTableName = [Contacts getTableName];//[self contactsTableName:currentUser];
    
    NSInteger count = [userList count];
    __weak typeof(self) weakSelf = self;
    [self.imService.imStorage.dbHelperInfo executeDB:^(FMDatabase *db) {
        
        for (NSInteger index = 0; index < count; ++ index) {
            User *user = [userList objectAtIndex:index];
          
            user.relation = relation;
            [weakSelf.imService.imStorage.userDao insertOrUpdateUser:user];
            
            if (relation == eUserRelation_black_active) {
                // 黑名单 不走批量插入
                [weakSelf.imService.imStorage.contactsDao insertOrUpdateContact:user owner:currentUser];
                
            } else {
                if (index == 0) {
                    [weakSelf.imService.imStorage.contactsDao insertOrUpdateContact:user owner:currentUser];
                } else {
                    NSString *sql = [weakSelf generatorContactSql:user inTable:contactTableName owner:currentUser];
                    
                    NSArray *arguments = @[@(user.userRole),
                                           user.remarkName==nil?@"":user.remarkName,
                                           @(currentUser.userId),
                                           @(currentUser.userRole),
                                           @(user.userId),
                                           user.createTime==nil?[NSDate date]:user.createTime,
                                           user.remarkHeader==nil?@"":user.remarkHeader,
                                           @(relation)
                                           ];
                    
                    [db executeUpdate:sql withArgumentsInArray:arguments];
                }
            }
        }
    }];
}

- (NSString *)generatorContactSql:(User *)contact inTable:(NSString *)tableName owner:(User *)owner;
{
    NSString *sql = @"replace into %@(contactRole,remarkName,userId, userRole,contactId,createTime,remarkHeader, relation) \
                               values(?,?,?,?,?,?,?, ?)";
    sql = [NSString stringWithFormat:sql, tableName];
    return sql;
}
//
//- (NSString *)contactsTableName:(User *)owner
//{
//    if (owner.userRole == eUserRole_Teacher)
//    {
//        return [TeacherContacts getTableName];
//    }
//    else if (owner.userRole == eUserRole_Institution)
//    {
//        return [InstitutionContacts getTableName];
//    }
//    else if (owner.userRole == eUserRole_Student)
//    {
//        return [StudentContacts getTableName];
//    }
//    return nil;
//}
//
- (NSString *)generatorGroupMmeberSql
{
    NSString *sql = @"replace into %@(msgStatus,isAdmin,canLeave,userId, \
                    pushStatus,userRole,createTime,canDisband,remarkHeader,remarkName,groupId, joinTime) values(?,?,?,?,?,?,?,?,?,?,?,?)";
    sql = [NSString stringWithFormat:sql, [GroupMember getTableName]];
    return sql;
}

@end
