//
//  StudentContacts.h
//  Pods
//
//  Created by 杨磊 on 15/7/27.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface StudentContacts : NSObject

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) int64_t contactId;
@property (nonatomic, assign) IMUserRole contactRole;
@property (nonatomic, assign) int16_t createTime;



@end
