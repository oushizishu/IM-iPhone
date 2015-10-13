//
//  HandleGetMsgOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/22.
//
//

#import "HandlePollingResultOperation.h"
#import "BJIMConstants.h"

@interface HandleGetMsgOperation : HandlePollingResultOperation

@property (nonatomic, copy) NSString *minMsgId;
@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) IMUserRole userRole;
@property (nonatomic, assign) int64_t groupId;

@end
