//
//  RecentContacts.h
//  Pods
//
//  Created by 杨磊 on 15/8/3.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface RecentContacts : NSObject

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) IMUserRole userRole;
@property (nonatomic, assign) int64_t contactId;
@property (nonatomic, assign) IMUserRole contactRole;
@property (nonatomic, assign) int16_t createTime;
@property (nonatomic, copy) NSString *markName;
@property (nonatomic, copy) NSString *markHeader;

@end
