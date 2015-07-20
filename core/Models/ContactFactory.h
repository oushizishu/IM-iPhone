//
//  ContactFactory.h
//  Pods
//
//  Created by 彭碧 on 15/7/20.
//
//

#import <Foundation/Foundation.h>
#import "Contacts.h"
#import "BJIMConstants.h"
@interface  StudentContacts:Contacts

@end

@interface  TeacherContacts:Contacts

@end

@interface  InstitutionContacts:Contacts

@end

@interface ContactFactory : NSObject
+ (Contacts*)convertToSubClassWithContact:(Contacts*)contact;
+ createContactWithUserRole:(IMUserRole)userRole;
@end
