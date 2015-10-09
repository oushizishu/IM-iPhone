//
//  UserDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "UserDao.h"
#import "InstitutionContacts.h"
#import "StudentContacts.h"
#import "TeacherContacts.h"
#import "BJIMStorage.h"

@implementation UserDao

- (User *)loadUser:(int64_t)userId role:(IMUserRole)userRole
{
    NSString *key = [NSString stringWithFormat:@"%lld-%ld", userId, (long)userRole];
    User *user = [self.identityScope objectByKey:key lock:YES];
    
    if (! user)
    {
        user = [self.dbHelper searchSingle:[User class] where:[NSString stringWithFormat:@"userId=%lld AND userRole=%ld",userId,(long)userRole] orderBy:nil];
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:@"userID and userRole" class:[User class]];
        
        if (user)
        {
            [self attachEntityKey:key entity:user lock:YES];
        }
    }
    else
    {
        [[DaoStatistics sharedInstance] logDBCacheSQL:nil class:[User class]];
    }
    return user;
}

- (User *)loadUserAndMarkName:(int64_t)userId role:(IMUserRole)userRole owner:(User *)owner
{
    User *user = [self loadUser:userId role:userRole];
    
    if (user)
    {
        if (owner.userRole == eUserRole_Institution)
        {
           InstitutionContacts *_contact = [self.imStroage.institutionDao loadContactId:userId contactRole:userRole owner:owner];
            user.remarkName = _contact.remarkName;
            user.remarkHeader = _contact.remarkHeader;
        }
        else if (owner.userRole == eUserRole_Student)
        {
            StudentContacts *_contact = [self.imStroage.studentDao loadContactId:userId contactRole:userRole owner:owner];
            user.remarkName = _contact.remarkName;
            user.remarkHeader = _contact.remarkHeader;
        }
        else if (owner.userRole == eUserRole_Teacher)
        {
            TeacherContacts *_contact = [self.imStroage.teacherDao loadContactId:userId contactRole:userRole owner:owner];
            user.remarkName = _contact.remarkName;
            user.remarkHeader = _contact.remarkHeader;
        }
    }
    return user;
}

- (void)insertOrUpdateUser:(User *)user
{
    User *_user = [self loadUser:user.userId role:user.userRole];
    if (_user)
    {
        _user.name = user.name;
        _user.avatar = user.avatar;
        [_user updateToDB];
        user.rowid = _user.rowid;
        
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" update " class:[User class]];
    }
    else
    {
        [self.dbHelper insertToDB:user];
        [[DaoStatistics sharedInstance] logDBOperationSQL:@" insert " class:[User class]];
    }
    [self attachEntityKey:[NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole] entity:user lock:YES];
}

@end
