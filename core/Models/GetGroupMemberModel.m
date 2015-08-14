//
//  GetGroupMemberModel.m
//  Pods
//
//  Created by Randy on 15/8/14.
//
//

#import "GetGroupMemberModel.h"

@implementation GetGroupMemberModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _userRole = eUserRole_Anonymous;
        _page = 1;
        _pageSize = MESSAGE_PAGE_COUNT;
    }
    return self;
}

@end
