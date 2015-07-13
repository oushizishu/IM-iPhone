//
//  User.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

/**
 * 确定一个 User 需要两个参数， userId 和 userRole
 */
@interface User : NSObject

@property (nonatomic, assign) int16_t userId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) IMUserRole userRole;

@end
