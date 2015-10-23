//
//  SocialContactsDao.m
//  Pods
//
//  Created by 杨磊 on 15/10/21.
//
//

#import "SocialContactsDao.h"
#import "User.h"
#import "BJIMStorage.h"

@implementation SocialContactsDao

- (NSString *)getKeyContactId:(int64_t)contactId
                  contactRole:(IMUserRole)contactRole
                      ownerId:(int64_t)ownerId
                    ownerRole:(IMUserRole)ownerRole
{
    NSString *key = [NSString stringWithFormat:@"%lld-%ld-%lld-%ld", contactId, (long)contactRole, ownerId, (long)ownerRole];
    return key;
}

- (SocialContacts *)loadContactId:(int64_t)contactId
                      contactRole:(IMUserRole)contactRole
                          ownerId:(int64_t)ownerId
                        ownerRole:(IMUserRole)ownerRole
{
    NSString *key = [self getKeyContactId:contactId contactRole:contactRole ownerId:ownerId ownerRole:ownerRole];
    SocialContacts *contact = [self.identityScope objectByKey:key lock:YES];
    if (contact == nil) {
       NSString *queryString = [NSString stringWithFormat:@" userId=%lld and userRole=%ld and contactId=%lld and contactRole=%ld",
                                ownerId, (long)ownerRole, contactId, (long)contactRole];
        contact = [self.dbHelper searchSingle:[SocialContacts class] where:queryString orderBy:nil];
        
        if (contact) {
            [self attachEntityKey:key entity:contact lock:YES];
        }
    }
    
    return contact;
}

- (void)update:(SocialContacts *)socialContact
{
    NSString *key = [self getKeyContactId:socialContact.contactId contactRole:socialContact.contactRole ownerId:socialContact.userId ownerRole:socialContact.userRole];
    [self attachEntityKey:key entity:socialContact lock:YES];
    [socialContact updateToDB];
}

- (BOOL)isStanger:(User *)contact withOwner:(User *)owner
{
    SocialContacts *social = [self loadContactId:contact.userId contactRole:contact.userRole ownerId:owner.userId ownerRole:owner.userRole];
    if (social == nil) {
        return YES;
    }
    
    if ((social.focusType == eIMFocusType_None && social.tinyFoucs == eIMTinyFocus_None) ||
        (social.focusType == eIMFocusType_Passive && social.tinyFoucs == eIMTinyFocus_None)) {
        return YES;
    }
    return NO;
}

- (IMFocusType)getAttentionState:(User *)contact withOwner:(User *)owner;
{
    SocialContacts *social = [self loadContactId:contact.userId contactRole:contact.userRole ownerId:owner.userId ownerRole:owner.userRole];
    return social.focusType;
}

- (IMTinyFocus)getTinyFoucsState:(User *)contact withOwner:(User *)owner
{
    SocialContacts *social = [self loadContactId:contact.userId contactRole:contact.userRole ownerId:owner.userId ownerRole:owner.userRole];
    return social.tinyFoucs;
}

- (IMBlackStatus)getBlacklistState:(User *)contact witOwner:(User *)owner
{
    SocialContacts *social = [self loadContactId:contact.userId contactRole:contact.userRole ownerId:owner.userId ownerRole:owner.userRole];
    return social.blackStatus;
}

- (void)setContactTinyFoucs:(IMTinyFocus)type contact:(User*)contact  owner:(User *)owner
{
    contact.tinyFocus = type;
    SocialContacts *social = [self loadContactId:contact.userId contactRole:contact.userRole ownerId:owner.userId ownerRole:owner.userRole];
    social.tinyFoucs = contact.tinyFocus;
    [social updateToDB];
    
    Conversation *conversation = [self.imStroage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:contact.userId userRole:contact.userRole chatType:eChatType_Chat];
    if (conversation != nil) {
        BOOL ifUpdateConversation = NO;
        if ([self isStanger:contact withOwner:owner] && conversation.relation != eConversation_Relation_Stranger) {
            ifUpdateConversation = YES;
            conversation.relation = eConversation_Relation_Stranger;
        }else if(![self isStanger:contact withOwner:owner] && conversation.relation != eConverastion_Relation_Normal){
            ifUpdateConversation = YES;
            conversation.relation = eConverastion_Relation_Normal;
        }
        if(ifUpdateConversation)
        {
            [self.imStroage.conversationDao update:conversation];
            
            Conversation *strangerConversation = [self.imStroage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:USER_STRANGER userRole:eUserRole_Stanger chatType:eChatType_Chat];
            if (strangerConversation) {
                NSString *maxMsgId = [self.imStroage.conversationDao queryStrangerConversationsMaxMsgId:owner.userId ownerRole:owner.userRole];
                if (! [strangerConversation.lastMessageId isEqualToString:maxMsgId]) {
                    strangerConversation.lastMessageId = maxMsgId;
                }
                strangerConversation.unReadNum = [self.imStroage.conversationDao countOfStrangerCovnersationAndUnreadNumNotZero:owner.userId userRole:owner.userRole];
                [self.imStroage.conversationDao update:strangerConversation];
            }
        }
    }
}

- (void)setContactFocusType:(BOOL)bAddFocus contact:(User*)user owner:(User *)owner
{
    if (bAddFocus) {
        if (user.focusType == eIMFocusType_None || user.focusType == eIMFocusType_Active) {
            user.focusType = eIMFocusType_Active;
        } else {
            user.focusType = eIMFocusType_Both;
        }
    } else {
        if (user.focusType == eIMFocusType_Both || user.focusType == eIMFocusType_Passive) {
            user.focusType = eIMFocusType_Passive;
        } else {
            user.focusType = eIMFocusType_None;
        }
    }
    
    SocialContacts *social = [self loadContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    if (! social) {
        social = [[SocialContacts alloc] init];
        social.userId = owner.userId;
        social.userRole = owner.userRole;
        social.contactId = user.userId;
        social.contactRole = user.userRole;
        social.blackStatus = user.blackStatus;
        social.originType = user.originType;
        social.focusType = user.focusType;
        social.tinyFoucs = user.tinyFocus;
        social.focusTime = user.focusTime;
        social.fansTime = user.fansTime;
        social.blackTime = user.blackTime;
        
        [self insert:social];
    } else {
        //更新关系字段
        social.focusType = user.focusType;
        [self update:social];
    }
    
    Conversation *conversation = [self.imStroage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:user.userId userRole:user.userRole chatType:eChatType_Chat];
    if (conversation != nil) {
        BOOL ifUpdateConversation = NO;
        if ([self isStanger:user withOwner:owner] && conversation.relation != eConversation_Relation_Stranger) {
            ifUpdateConversation = YES;
            conversation.relation = eConversation_Relation_Stranger;
        }else if(![self isStanger:user withOwner:owner] && conversation.relation != eConverastion_Relation_Normal){
            ifUpdateConversation = YES;
            conversation.relation = eConverastion_Relation_Normal;
        }
        if(ifUpdateConversation)
        {
            [self.imStroage.conversationDao update:conversation];
            
            Conversation *strangerConversation = [self.imStroage.conversationDao loadWithOwnerId:owner.userId ownerRole:owner.userRole otherUserOrGroupId:USER_STRANGER userRole:eUserRole_Stanger chatType:eChatType_Chat];
            if (strangerConversation) {
                NSString *maxMsgId = [self.imStroage.conversationDao queryStrangerConversationsMaxMsgId:owner.userId ownerRole:owner.userRole];
                if (! [strangerConversation.lastMessageId isEqualToString:maxMsgId]) {
                    strangerConversation.lastMessageId = maxMsgId;
                }
                strangerConversation.unReadNum = [self.imStroage.conversationDao countOfStrangerCovnersationAndUnreadNumNotZero:owner.userId userRole:owner.userRole];
                [self.imStroage.conversationDao update:strangerConversation];
            }
        }
    }
}

- (void)setContactBacklist:(IMBlackStatus)status contact:(User*)contact owner:(User*)owner
{
    contact.blackStatus = status;
    SocialContacts *social = [self loadContactId:contact.userId contactRole:contact.userRole ownerId:owner.userId ownerRole:owner.userRole];
    social.blackStatus = contact.blackStatus;
    [self update:social];
}


- (NSArray *)loadAllAttentions:(User *)owner contactRole:(IMUserRole)contactRole;
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [self.dbHelper executeDB:^(FMDatabase *db) {
        
        // 采用内级联查询
        NSString *query = [NSString stringWithFormat:@"select \
                           USERS.rowid, USERS.userId, USERS.userRole,  USERS.name,USERS.avatar, USERS.nameHeader, \
                           SOCIALCONTACTS.remarkName, SOCIALCONTACTS.remarkHeader \
                           SOCIALCONTACTS.blackStatus, SOCIALCONTACTS.originType, SOCIALCONTACTS.focusType \
                           SOCIALCONTACTS.tinyFoucs, SOCIALCONTACTS.focusTime,SOCIALCONTACTS.fansTime \
                           from USERS INNER JOIN SOCIALCONTACTS ON USERS.userId=SOCIALCONTACTS.contactId and \
                           USERS.userRole=SOCIALCONTACTS.contactRole where SOCIALCONTACTS.userId=%lld and \
                           SOCIALCONTACTS.userRole=%ld and SOCIALCONTACTS.blackStatus<>%ld and (SOCIALCONTACTS.focusType=%ld \
                           or SOCIALCONTACTS.focusType=%ld) ",
                           owner.userId, owner.userRole, eIMBlackStatus_Active, eIMFocusType_Active, eIMFocusType_Both];
        
        if (contactRole > 0) {
            query = [NSString stringWithFormat:@"%@ and SOCIALCONTACTS.contactRole=%ld ",query, (long)contactRole];
        }
        
        query = [NSString stringWithFormat:@"%@ order by SOCIALCONTACTS.focusTime desc", query];
        
        
        FMResultSet *set = [db executeQuery:query];
        
        while ([set next]) {
            User *user = [[User alloc] init];
            user.rowid = [set longForColumnIndex:0];
            user.userId = [set longLongIntForColumnIndex:1];
            user.userRole = [set longForColumnIndex:2];
            user.name = [set stringForColumnIndex:3];
            user.avatar = [set stringForColumnIndex:4];
            user.nameHeader = [set stringForColumnIndex:5];
            user.remarkName = [set stringForColumnIndex:6];
            user.remarkHeader = [set stringForColumnIndex:7];
            
            user.blackStatus = [set longForColumnIndex:8];
            user.originType = [set longForColumnIndex:9];
            user.focusType = [set longForColumnIndex:10];
            user.tinyFocus = [set longForColumnIndex:11];
            user.focusTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:12]];
            user.fansTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:13]];
            
            NSString *key = [NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole];
            [self.imStroage.userDao attachEntityKey:key entity:user lock:YES];
            
            [users addObject:user];
        }
        
        [set close];
    }];
    return users;
}

- (NSArray *)loadAllFans:(User *)owner
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [self.dbHelper executeDB:^(FMDatabase *db) {
        
        // 采用内级联查询
        NSString *query = [NSString stringWithFormat:@"select \
                           USERS.rowid, USERS.userId, USERS.userRole,  USERS.name,USERS.avatar, USERS.nameHeader, \
                           SOCIALCONTACTS.remarkName, SOCIALCONTACTS.remarkHeader \
                           SOCIALCONTACTS.blackStatus, SOCIALCONTACTS.originType, SOCIALCONTACTS.focusType \
                           SOCIALCONTACTS.tinyFoucs, SOCIALCONTACTS.focusTime,SOCIALCONTACTS.fansTime \
                           from USERS INNER JOIN SOCIALCONTACTS ON USERS.userId=SOCIALCONTACTS.contactId and \
                           USERS.userRole=SOCIALCONTACTS.contactRole where SOCIALCONTACTS.userId=%lld and \
                           SOCIALCONTACTS.userRole=%ld and SOCIALCONTACTS.blackStatus<>%ld and SOCIALCONTACTS.focusType=%ld \
                           or SOCIALCONTACTS.focusType=%ld order by SOCIALCONTACTS.fansTime desc;",
                           owner.userId, owner.userRole, eIMBlackStatus_Active, eIMFocusType_Passive, eIMFocusType_Both];
        
        
        FMResultSet *set = [db executeQuery:query];
        
        while ([set next]) {
            User *user = [[User alloc] init];
            user.rowid = [set longForColumnIndex:0];
            user.userId = [set longLongIntForColumnIndex:1];
            user.userRole = [set longForColumnIndex:2];
            user.name = [set stringForColumnIndex:3];
            user.avatar = [set stringForColumnIndex:4];
            user.nameHeader = [set stringForColumnIndex:5];
            user.remarkName = [set stringForColumnIndex:6];
            user.remarkHeader = [set stringForColumnIndex:7];
            
            user.blackStatus = [set longForColumnIndex:8];
            user.originType = [set longForColumnIndex:9];
            user.focusType = [set longForColumnIndex:10];
            user.tinyFocus = [set longForColumnIndex:11];
            user.focusTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:12]];
            user.fansTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:13]];
            
            NSString *key = [NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole];
            [self.imStroage.userDao attachEntityKey:key entity:user lock:YES];
            
            [users addObject:user];
        }
        
        [set close];
    }];
    return users;
}

- (NSArray *)loadAllBlacks:(User *)owner
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [self.dbHelper executeDB:^(FMDatabase *db) {
        
        // 采用内级联查询
        NSString *query = [NSString stringWithFormat:@"select \
                           USERS.rowid, USERS.userId, USERS.userRole,  USERS.name,USERS.avatar, USERS.nameHeader, \
                           SOCIALCONTACTS.remarkName, SOCIALCONTACTS.remarkHeader \
                           SOCIALCONTACTS.blackStatus, SOCIALCONTACTS.originType, SOCIALCONTACTS.focusType \
                           SOCIALCONTACTS.tinyFoucs, SOCIALCONTACTS.focusTime,SOCIALCONTACTS.fansTime \
                           from USERS INNER JOIN SOCIALCONTACTS ON USERS.userId=SOCIALCONTACTS.contactId and \
                           USERS.userRole=SOCIALCONTACTS.contactRole where SOCIALCONTACTS.userId=%lld and \
                           SOCIALCONTACTS.userRole=%ld and SOCIALCONTACTS.blackStatus=%ld \
                           order by SOCIALCONTACTS.blackTime desc;",
                           owner.userId, owner.userRole, eIMBlackStatus_Active];
        
        FMResultSet *set = [db executeQuery:query];
        
        while ([set next]) {
            User *user = [[User alloc] init];
            user.rowid = [set longForColumnIndex:0];
            user.userId = [set longLongIntForColumnIndex:1];
            user.userRole = [set longForColumnIndex:2];
            user.name = [set stringForColumnIndex:3];
            user.avatar = [set stringForColumnIndex:4];
            user.nameHeader = [set stringForColumnIndex:5];
            user.remarkName = [set stringForColumnIndex:6];
            user.remarkHeader = [set stringForColumnIndex:7];
            
            user.blackStatus = [set longForColumnIndex:8];
            user.originType = [set longForColumnIndex:9];
            user.focusType = [set longForColumnIndex:10];
            user.tinyFocus = [set longForColumnIndex:11];
            user.focusTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:12]];
            user.fansTime = [NSDate dateWithTimeIntervalSince1970:[set doubleForColumnIndex:13]];
            
            NSString *key = [NSString stringWithFormat:@"%lld-%ld", user.userId, (long)user.userRole];
            [self.imStroage.userDao attachEntityKey:key entity:user lock:YES];
            
            [users addObject:user];
        }
        
        [set close];
    }];
    return users;
}

- (NSArray *)loadAllAttentionsStudent:(User *)owner
{
    return [self loadAllAttentions:owner contactRole:eUserRole_Student];
}

- (NSArray *)loadAllAttentionsTeacher:(User *)owner
{
    return [self loadAllAttentions:owner contactRole:eUserRole_Teacher];
}

- (NSArray *)loadAllAttentionsInstitution:(User *)owner
{
    return [self loadAllAttentions:owner contactRole:eUserRole_Institution];
}

- (NSArray *)loadAllAttentions:(User *)owner
{
    return [self loadAllAttentions:owner contactRole:-1];
}

- (void)insert:(User *)user withOwner:(User *)owner
{
    SocialContacts *contact = [[SocialContacts alloc] init];
    contact.userId = owner.userId;
    contact.userRole = owner.userRole;
    contact.contactId = user.userId;
    contact.contactRole = user.userRole;
    contact.blackStatus = user.blackStatus;
    contact.originType = user.originType;
    contact.focusType = user.focusType;
    contact.tinyFoucs = user.tinyFocus;
    contact.focusTime = user.focusTime;
    contact.fansTime = user.fansTime;
    contact.blackTime = user.blackTime;
    
    [self insert:contact];
}

- (void)insert:(SocialContacts *)contact
{
    NSString *key = [self getKeyContactId:contact.userId contactRole:contact.userRole ownerId:contact.userId ownerRole:contact.userRole];
    [self.dbHelper insertToDB:contact];
    [self attachEntityKey:key entity:contact lock:YES];

}

- (void)clearAll:(User *)owner;
{
    NSString *query = [NSString stringWithFormat:@"delete from %@ where userId=%lld and userRole=%ld", [SocialContacts getTableName], owner.userId, (long)owner.userRole];
    [self.dbHelper executeSQL:query arguments:nil];
}

- (void)deleteFreshFans:(User *)user withOwner:(User *)owner
{
    NSString *key = [self getKeyContactId:user.userId contactRole:user.userRole ownerId:owner.userId ownerRole:owner.userRole];
    [self detach:key lock:YES];
    NSString *sql = [NSString stringWithFormat:@" userId=%lld and userRole=%ld and contactId=%lld and contactRole=%ld",
                     owner.userId, (long)owner.userRole, user.userId, (long)user.userRole];
    [self.dbHelper deleteWithClass:[SocialContacts class] where:sql callback:nil];
}


@end
