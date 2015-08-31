//
//  IdentityScope.h
//  Concurrent
//
//  Created by 杨磊 on 15/8/29.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IdentityScope : NSObject

- (void)lock;
- (void)unlock;
- (id)objectByKey:(id)key lock:(BOOL)lock;
- (id)objectByCondition:(BOOL (^)(id key, id item))condition lock:(BOOL)lock;
- (void)appendObject:(id)object key:(id)key lock:(BOOL)lock;
- (void)clear;
- (void)removeObjectForKey:(id)key lock:(BOOL)lock;
@end
