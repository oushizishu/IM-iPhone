//
//  TransformContactInfoToNewDBOperation.m
//  Pods
//
//  Created by 杨磊 on 16/3/7.
//
//

#import "TransformContactInfoToNewDBOperation.h"
#import "BJIMService.h"

#import "StudentContacts.h"
#import "TeacherContacts.h"
#import "InstitutionContacts.h"
#import "Contacts.h"
#import "IMEnvironment.h"
#import "GroupMember.h"


@implementation TransformContactInfoToNewDBOperation

- (void)doOperationOnBackground
{
    __weak typeof(self) weakSelf = self;
    [self.imService.imStorage.dbHelper executeDB:^(FMDatabase *db) {
        [weakSelf transformUserTable:db];
        [weakSelf transformContactsTable:db];
        [weakSelf transformGroupTable:db];
        [weakSelf transformGroupMemberTable:db];
    }];
}

/**
 *  迁移 User 表数据
 *
 *  @param db <#db description#>
 */
- (void)transformUserTable:(FMDatabase *)db
{
    NSString *sql = [NSString stringWithFormat:@"select avatar, userRole, userId, name, nameHeader from \
                     %@", [User getTableName]];
    FMResultSet * resultSet = [db executeQuery:sql];
   
    NSString *insert = [NSString stringWithFormat:@"insert into %@ (avatar, userRole, userId, name, nameHeader) \
                        values(?,?,?,?,?,?)", [User getTableName]];
    while ([resultSet next]) {
        NSArray *arguments = @[
                              [resultSet stringForColumnIndex:0],
                              [NSNumber numberWithInteger:[resultSet intForColumnIndex:1]],
                              [NSNumber numberWithLong:[resultSet longForColumnIndex:2]],
                              [resultSet stringForColumnIndex:3],
                              [resultSet stringForColumnIndex:4]
                               ];
        [self.imService.imStorage.dbHelperInfo executeSQL:insert arguments:arguments];
    }
    
    [resultSet close];
}

- (void)transformContactsTable:(FMDatabase *)db
{
    NSString *tableName = [StudentContacts getTableName];
    IMUserRole userRole = eUserRole_Student;
    if ([IMEnvironment shareInstance].owner.userRole == eUserRole_Teacher) {
        tableName = [TeacherContacts getTableName];
        userRole = eUserRole_Teacher;
    } else if ([IMEnvironment shareInstance].owner.userRole == eUserRole_Institution) {
        tableName = [InstitutionContacts getTableName];
        userRole = eUserRole_Institution;
    }
    
    NSString *sql = [NSString stringWithFormat:@"select userId, contactId, contactRole, createTime, remarkName, remarkHeader\
                     from %@", tableName];
    
    FMResultSet *resultSet = [db executeQuery:sql];
   
    NSString *insert = [NSString stringWithFormat:@"insert into %@ (userId, userRole, contactId, contactRole,\
                        createTime, remarkName, remarkHeader) values(?,?,?,?,?,?,?)", [Contacts getTableName]];
    while ([resultSet next]) {
        NSArray *arguments = @[
                               [NSNumber numberWithLong:[resultSet longForColumnIndex:0]], //userId
                               [NSNumber numberWithLong:userRole], //userRole
                               [NSNumber numberWithLong:[resultSet longForColumnIndex:1]], //contactId
                               [NSNumber numberWithLong:[resultSet longForColumnIndex:2]], //contactRole
                               [resultSet dateForColumnIndex:3], //createTime
                               [resultSet stringForColumnIndex:4], //remarkName
                               [resultSet stringForColumnIndex:5] //remarkHeader
                               ];
        [self.imService.imStorage.dbHelperInfo executeSQL:insert arguments:arguments];
    }
    
    [resultSet close];
}

- (void)transformGroupTable:(FMDatabase *)db
{
    NSString *sql = [NSString stringWithFormat:@"select groupId, groupName, avatar, descript, isPublic, maxusers, \
                     approval, ownerId, ownerRole, memberCount, status, createTime, nameHeader, isAdmin from \
                     %@", [Group getTableName]];
    
    FMResultSet *resultSet = [db executeQuery:sql];
    
    NSString *insert = [NSString stringWithFormat:@"insert into %@ (groupId, groupName, avatar, descript, isPublic, \
                        maxusers, approval, ownerId, ownerRole, memberCount, status, createTime, nameHeader, isAdmin) values \
                        (?,?,?,?,?,?,?,?,?,?,?,?,?,?)", [Group getTableName]];
    
    while ([resultSet next]) {
        NSArray *arguments = @[
                               [NSNumber numberWithLong:[resultSet longForColumnIndex:0]], //groupId
                               [resultSet stringForColumnIndex:1], //groupName
                               [resultSet stringForColumnIndex:2], //avatar
                               [resultSet stringForColumnIndex:3], //descript
                               [NSNumber numberWithBool:[resultSet boolForColumnIndex:4]], //isPublic
                               [NSNumber numberWithInteger:[resultSet intForColumnIndex:5]], //maxusres
                               [NSNumber numberWithInteger:[resultSet intForColumnIndex:6]], //approval
                               [NSNumber numberWithLong:[resultSet longForColumnIndex:7]], //ownerId
                               [NSNumber numberWithInteger:[resultSet intForColumnIndex:8]], //ownerRole
                               [NSNumber numberWithInteger:[resultSet intForColumnIndex:9]], //memberCount
                               [NSNumber numberWithInteger:[resultSet intForColumnIndex:10]], //status
                               [resultSet dateForColumnIndex:11], //createTime
                               [resultSet stringForColumnIndex:12], //nameHeader
                               [NSNumber numberWithBool:[resultSet boolForColumnIndex:13]] //isAdmin
                               ];
        [self.imService.imStorage.dbHelperInfo executeSQL:insert arguments:arguments];
    }

    [resultSet close];
}

- (void)transformGroupMemberTable:(FMDatabase *)db
{
    NSString *sql = [NSString stringWithFormat:@"select userId, userRole, groupId, isAdmin, createTime\
                     msgStatus, canLeave, canDisband, pushStatus, remarkName, remarkHeader, joinTime \
                     from %@", [GroupMember getTableName]];
    FMResultSet *resultSet = [db executeQuery:sql];
    
    NSString *insert = [NSString stringWithFormat:@"insert into %@ (userId, userRole, groupId, isAdmin, createTime\
                        msgStatus, canLeave, canDisband, pushStatus, remarkName, remarkHeader, joinTime) \
                        values(?,?,?,?,?,?,?,?,?,?,?,?)", [GroupMember getTableName]];
    
    while ([resultSet next]) {
        NSArray *arguments = @[
                                [NSNumber numberWithLong:[resultSet longForColumnIndex:0]],
                                [NSNumber numberWithLong:[resultSet longForColumnIndex:1]],
                                [NSNumber numberWithLong:[resultSet longForColumnIndex:2]],
                                [NSNumber numberWithBool:[resultSet boolForColumnIndex:3]],
                                [resultSet dateForColumnIndex:4],
                                [NSNumber numberWithInteger:[resultSet intForColumnIndex:5]],
                                [NSNumber numberWithBool:[resultSet boolForColumnIndex:6]],
                                [NSNumber numberWithBool:[resultSet boolForColumnIndex:7]],
                                [NSNumber numberWithInteger:[resultSet intForColumnIndex:8]],
                                [resultSet stringForColumnIndex:9],
                                [resultSet stringForColumnIndex:10],
                                [resultSet dateForColumnIndex:11]
                               ];
        [self.imService.imStorage.dbHelperInfo executeSQL:insert arguments:arguments];
    }
    
    [resultSet close];
}

@end
