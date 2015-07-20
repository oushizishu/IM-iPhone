//
//  Group.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import <LKDBHelper/NSObject+LKModel.h>

@interface Group : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t groupId ;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *descript;
@property (nonatomic, assign) NSInteger isPublic;
@property (nonatomic, assign) NSInteger maxusers;
@property (nonatomic, assign) NSInteger approval;
@property (nonatomic, assign) int64_t ownerId;
@property (nonatomic, assign) IMUserRole ownerRole;
@property (nonatomic, assign) NSInteger memberCount;
@property (nonatomic, assign) NSInteger status; // 0 保留 1 开发 2删除
@property (nonatomic, assign) int64_t createTime;

@property (nonatomic, assign) double lastMessageId;
@property (nonatomic, assign) double startMessageId;
@property (nonatomic, assign) double endMessageId;
@end
