//
//  GroupDetail.h
//
//  Created by wangziliang on 15/12/4.
//
//

#import "MTLModel.h"
#import "BJIMConstants.h"

@interface GroupDetail : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t group_id;
@property (nonatomic, strong) NSString *group_name;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, strong) NSString *maxusers;
@property (nonatomic, strong) NSString *user_id;
@property (nonatomic, strong) NSString *user_role;
@property (nonatomic, strong) NSString *membercount;

@end
