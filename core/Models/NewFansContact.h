//
//  NewFansContact.h
//  Pods
//
//  Created by 杨磊 on 15/10/19.
//
//

#import "MTLModel.h"
#import "BJIMConstants.h"

@interface NewFansContact : MTLModel

@property (nonatomic, assign) int64_t userId;
@property (nonatomic, assign) IMUserRole userRole;
@property (nonatomic, assign) int64_t fansId;
@property (nonatomic, assign) IMUserRole fansRole;

@end
