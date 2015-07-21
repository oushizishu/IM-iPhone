//
//  ContactFactory.m
//  Pods
//
//  Created by 彭碧 on 15/7/20.
//
//

#import "ContactFactory.h"

@implementation StudentContacts
@end
@implementation TeacherContacts
@end
@implementation InstitutionContacts
@end
@implementation ContactFactory
+(id)createContactWithUserRole:(IMUserRole)userRole
{
    switch (userRole) {
        case eUserRole_Student:{
            return [[StudentContacts alloc] init];
        }break;
        case eUserRole_Teacher:{
            return [[TeacherContacts alloc] init];
        }break;
        case eUserRole_Institution:{
            return [[InstitutionContacts alloc] init];
        }break;
        default:
            break;
    }
    return nil;
}
+(Contacts *)convertToSubClassWithContact:(Contacts *)contact
{
    IMUserRole  userRole = contact.contactRole;
    Contacts *newContact = [self createContactWithUserRole:userRole];
    newContact.userId = contact.userId;
    newContact.contactRole = userRole;
    newContact.contactId = contact.contactId;
    newContact.createTime = contact.createTime;
    return newContact;
}
@end
