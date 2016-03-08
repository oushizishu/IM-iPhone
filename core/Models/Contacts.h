//
//  Contacts.h
//  Pods
//
//  Created by 杨磊 on 16/3/7.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

/**
 *  联系人表， 去除之前版本针对不同角色使用不同的表存储。
 *  4.1 版本之后使用一个表存储联系人关系数据
 */
@interface Contacts : NSObject

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) IMUserRole userRole;
@property (nonatomic, assign) int64_t contactId;
@property (nonatomic, assign) IMUserRole contactRole;
@property (nonatomic, copy) NSDate *createTime;
@property (nonatomic, copy) NSString *remarkName;
@property (nonatomic, copy) NSString *remarkHeader;

@property (nonatomic, assign) IMUserRelation relation;

@end
