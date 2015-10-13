//
//  PollingResultModel.h
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface UnReadNum : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t group_id;
@property (nonatomic, assign) NSInteger num;

@end

@interface Info  : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSString *firstMsgId;
@end

@interface PollingResultModel :MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray *msgs;
@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *unread_number;
@property (nonatomic, strong) NSArray *ops;
@property (nonatomic, strong) Info    *info;

@end
