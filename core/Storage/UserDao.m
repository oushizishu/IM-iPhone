//
//  UserDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "UserDao.h"
//#import "InstitutionContacts.h"
//#import "StudentContacts.h"
//#import "TeacherContacts.h"
#import "ContactsDao.h"
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
        Contacts *contact = [self.imStroage.contactsDao loadContactId:userId contactRole:userRole owner:owner];
        user.remarkName = contact.remarkName;
        user.remarkHeader = contact.remarkHeader;
        user.createTime = contact.createTime;
    }
    return user;
}

- (void)insertOrUpdateUser:(User *)user
{
    User *_user = [self loadUser:user.userId role:user.userRole];
    if (_user)
    {
        NSInteger rowid = _user.rowid;
        _user.rowid = rowid;
        _user.onlineStatus = user.onlineStatus;
        [self update:_user];
    }
    else
    {
        [self.dbHelper insertToDB:user];
        [self attachEntityKey:[NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole] entity:user lock:YES];
    }
}

- (void)update:(User *)user {
    NSString *key = [NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole];
    NSString *string = [NSString stringWithFormat:@" userId=%lld and userRole=%ld", user.userId, (long)user.userRole];
    [self.dbHelper updateToDB:user where:string];
    [self attachEntityKey:key entity:user lock:YES];
}

@end
