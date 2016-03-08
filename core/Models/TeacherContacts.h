//
//  TeacherContacts.h
//  Pods
//
//  Created by 杨磊 on 15/7/27.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

/**
 *  4.1 版本之后被废弃。 使用 {@link Contacts}
 */
@interface TeacherContacts : NSObject

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) int64_t contactId;
@property (nonatomic, assign) IMUserRole contactRole;
@property (nonatomic, assign) int16_t createTime;
@property (nonatomic, copy) NSString *remarkName;
@property (nonatomic, copy) NSString *remarkHeader;

@end
