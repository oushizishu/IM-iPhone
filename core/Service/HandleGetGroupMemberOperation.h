//
//  HandleGetGroupMemberOperation.h
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import "IMBaseOperation.h"
#import "BJIMService.h"

@interface HandleGetGroupMemberOperation : IMBaseOperation
- (instancetype)initWithService:(BJIMService *)service listData:(GroupMemberListData *)listData;

@end
