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
@property (nonatomic, assign) NSInteger status; // 0 保留 1 开放 2删除
@property (nonatomic, assign) int64_t createTime;

@property (nonatomic, assign) IMGroupMsgStatus msgStatus;
@property (nonatomic, assign) BOOL canLeave;//是否
@property (nonatomic, assign) BOOL canDisband;//是否能解散

@property (nonatomic, copy) NSString *nameHeader; // 名字首字母
@property (nonatomic, copy) NSString *remarkName; //备注名
@property (nonatomic, copy) NSString *remarkHeader; //备注首字母

@property (nonatomic, assign) double lastMessageId;
@property (nonatomic, assign) double startMessageId;
@property (nonatomic, assign) double endMessageId;
@end
