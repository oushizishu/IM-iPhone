//
//  Group.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface Group : NSObject

@property (nonatomic, assign) int64_t groupId ;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *descript;
@property (nonatomic, assign) NSInteger is_public;
@property (nonatomic, assign) NSInteger maxusers;
@property (nonatomic, assign) NSInteger approval;
@property (nonatomic, assign) int64_t owner_id;
@property (nonatomic, assign) IMUserRole owner_role;
@property (nonatomic, assign) NSInteger membercount;
@property (nonatomic, assign) NSInteger status; // 0 保留 1 开发 2删除
@property (nonatomic, assign) int64_t create_time;

@property (nonatomic, assign)int64_t last_message_id;
@property (nonatomic, assign)int64_t start_message_id;
@property (nonatomic, assign)int64_t end_message_id;
@end
