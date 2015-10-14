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
    [self executorContacts:organizationList deleteContactRole:eUserRole_Institution];
   
   
    //更新学生联系人
    NSArray *studentList = self.model.studentList;
    [self executorContacts:studentList deleteContactRole:eUserRole_Student];
    
    // 更新老师联系人
    NSArray *teacherList = self.model.teacherList;
    [self executorContacts:teacherList deleteContactRole:eUserRole_Teacher];
    
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyContactChanged];
}

- (void)executorContacts:(NSArray *)userList deleteContactRole:(IMUserRole)contactRole
{
    User *currentUser = [IMEnvironment shareInstance].owner;
    NSString *contactTableName = [self contactsTableName:currentUser];
    
    NSString *deleteSQL = [NSString stringWithFormat:@"delete from %@ where userId=%lld and contactRole=%ld", contactTableName, currentUser.userId, (long)contactRole];
    
    NSInteger count = [userList count];
    __weak typeof(self) weakSelf = self;
    [self.imService.imStorage.dbHelper executeForTransaction:^BOOL(LKDBHelper *helper) {
        @try {
            
            [helper executeSQL:deleteSQL arguments:nil];
            
            for (NSInteger index = 0; index < count; ++ index) {
                User *user = [userList objectAtIndex:index];
                
                if (index == 0) {
                    [weakSelf.imService.imStorage.userDao insertOrUpdateUser:user];
                    [weakSelf.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
                }
                
                // 插入用户，如果已经存在则不插入
                if (index != 0) {
                    [helper executeDB:^(FMDatabase *db) {
                        NSString *query = [NSString stringWithFormat:@"select * from %@ where userId=%lld and userRole=%ld", [User getTableName], user.userId, (long)user.userRole];
                        FMResultSet *set = [db executeQuery:query];
                        if (! [set next]) {
                            // 数据库中没有这个用户
                            NSString *sql = [weakSelf generatorUserSql:user];
                            [helper executeSQL:sql arguments:nil];
                        }
                        [set close];
                    }];
                }
                
                
                NSString *sql = [weakSelf generatorContactSql:user inTable:contactTableName owner:currentUser];
                [helper executeSQL:sql arguments:nil];
                
            }
            return YES;
        }
        @catch (NSException *exception) {
            return NO;
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
                           contact.remarkHeader];

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
                           groupMember.remarkHeader,
                           groupMember.remarkName,
                           groupMember.groupId];
    NSString *sql = @"replace into %@(msgStatus,isAdmin,canLeave,userId, \
                    pushStatus,userRole,createTime,canDisband,remarkHeader,remarkName,groupId) values%@";
    sql = [NSString stringWithFormat:sql, [GroupMember getTableName],arguments];
    return sql;
}
@end
