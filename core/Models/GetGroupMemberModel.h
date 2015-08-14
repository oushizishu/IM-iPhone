//
//  GetGroupMemberModel.h
//  Pods
//
//  Created by Randy on 15/8/14.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
@interface GetGroupMemberModel : NSObject
@property (assign, nonatomic) int64_t groupId;
@property (assign, nonatomic) IMUserRole userRole;
@property (assign, nonatomic) NSUInteger page;
@property (assign, nonatomic) NSInteger pageSize;

@end
