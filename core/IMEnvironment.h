//
//  IMEnvironment.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>

@interface IMEnvironment : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, copy, readonly) NSString *oAuthToken;

@end
