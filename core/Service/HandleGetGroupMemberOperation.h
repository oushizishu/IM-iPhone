//
//  HandleGetGroupMemberOperation.h
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import "IMBaseOperation.h"
#import "BJIMService.h"
@class GetGroupMemberModel;
@interface HandleGetGroupMemberOperation : IMBaseOperation
@property (strong, nonatomic) GetGroupMemberModel *model;
- (instancetype)initWithService:(BJIMService *)service listData:(GroupMemberListData *)listData;

@end
