//
//  SearchMember.h
//  Pods
//
//  Created by 辛亚鹏 on 2017/2/15.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

@interface SearchMember : MTLModel<MTLJSONSerializing>

@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *userNumber;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *avatar;

@property (nonatomic) IMUserRole userRole;
@property (nonatomic) IMGroupMsgStatus msgStatus;
@property (nonatomic) NSInteger pushStatus;
@property (nonatomic) BOOL isMajor;
@property (nonatomic) BOOL isAdmin;

@end
//
//@interface SearchMemberList : MTLModel<MTLJSONSerializing>
//
//@property (nonatomic) NSArray <SearchMember *> *memberList;
//
//@end
