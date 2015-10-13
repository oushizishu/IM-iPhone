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
    NSString *contactTablename = [self contactsTableName:currentUser];
    [excutorSQLs removeAllObjects];
    NSArray *organizationList = self.model.organizationList;
    count = organizationList.count;
    
    for (NSInteger index = 0; index < count; ++index) {
        User *user = [organizationList objectAtIndex:index];
        if (index == 0) {
            [self.imService.imStorage.userDao insertOrUpdateUser:user];
            [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
        }
        
        NSString *sql = [self generatorUserSql:user];
        [excutorSQLs addObject:sql];
        
        sql = [self generatorContactSql:user inTable:contactTablename owner:currentUser];
        [excutorSQLs addObject:sql];
    }
    
    NSString *deleteOrganizationContactsSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and contactRole=%ld", contactTablename, currentUser.userId, (long)eUserRole_Institution];
    [self.imService.imStorage.dbHelper executeForTransaction:^BOOL(LKDBHelper *helper) {
        @try {
            [helper executeSQL:deleteOrganizationContactsSql arguments:nil];
            NSInteger count = [excutorSQLs count];
            for (NSInteger index = 0; index < count; ++ index) {
                [helper executeSQL:[excutorSQLs objectAtIndex:index] arguments:nil];
            }
                
            return YES;
        }
        @catch (NSException *exception) {
            return NO;
        }
    }];
    
    //更新学生联系人
    [excutorSQLs removeAllObjects];
    NSArray *studentList = self.model.studentList;
    count = [studentList count];
    for (NSInteger index = 0; index < count; ++ index) {
        User *user = [studentList objectAtIndex:index];
        if (index == 0) {
            [self.imService.imStorage.userDao insertOrUpdateUser:user];
            [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
        }
        NSString *sql = [self generatorUserSql:user];
        [excutorSQLs addObject:sql];
        
        sql = [self generatorContactSql:user inTable:contactTablename owner:currentUser];
        [excutorSQLs addObject:sql];
    }
    NSString *deleteStudentContactsSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and contactRole=%ld", contactTablename, currentUser.userId, (long)eUserRole_Student];
    [self.imService.imStorage.dbHelper executeForTransaction:^BOOL(LKDBHelper *helper) {
        @try {
            [helper executeSQL:deleteStudentContactsSql arguments:nil];
            NSInteger count = [excutorSQLs count];
            for (NSInteger index = 0; index < count; ++ index) {
                [helper executeSQL:[excutorSQLs objectAtIndex:index] arguments:nil];
            }
            return YES;
        }
        @catch (NSException *exception) {
            return NO;
        }
    }];
    
    // 更新老师联系人
    [excutorSQLs removeAllObjects];
    NSArray *teacherList = self.model.teacherList;
    count = [teacherList count];
    for (NSInteger index = 0; index < count; ++ index) {
        User *user = [teacherList objectAtIndex:index];
        if (index == 0) {
            [self.imService.imStorage.userDao insertOrUpdateUser:user];
            [self.imService.imStorage insertOrUpdateContactOwner:currentUser contact:user];
        }
        
        NSString *sql = [self generatorUserSql:user];
        [excutorSQLs addObject:sql];
        
        sql = [self generatorContactSql:user inTable:contactTablename owner:currentUser];
        [excutorSQLs addObject:sql];
    }
    NSString *deleteTeacherContactsSql = [NSString stringWithFormat:@"delete from %@ where userId=%lld and contactRole=%ld", contactTablename, currentUser.userId, (long)eUserRole_Teacher];
    [self.imService.imStorage.dbHelper executeForTransaction:^BOOL(LKDBHelper *helper) {
        @try {
            [helper executeSQL:deleteTeacherContactsSql arguments:nil];
            NSInteger count = [excutorSQLs count];
            for (NSInteger index = 0; index < count; ++index) {
                [helper executeSQL:[excutorSQLs objectAtIndex:index] arguments:nil];
            }
            return YES;
        }
        @catch (NSException *exception) {
            return NO;
        }
    }];
}

- (void)doAfterOperationOnMain
{
    [self.imService notifyContactChanged];
}

- (NSString *)generatorUserSql:(User *)user
{

    NSString *arguments = [NSString stringWithFormat:@"(%lld,'%@','%@',%ld)",
                           user.userId,
                           user.name,
                           user.avatar,
                           (long)user.userRole];
    NSString *sql = @"replace into %@(userId,name,avatar,userRole) values%@";
    sql = [NSString stringWithFormat:sql, arguments];
    return nil;
}

- (NSString *)generatorContactSql:(User *)contact inTable:(NSString *)tableName owner:(User *)owner;
{
    NSString *arguments = [NSString stringWithFormat:@"(%ld,'%@',%lld,%lld,%lld,'%@')",
                           (long)contact.userRole,
                           contact.remarkName,
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
