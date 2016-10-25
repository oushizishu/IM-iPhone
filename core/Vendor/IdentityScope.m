//
//  IdentityScope.m
//  Concurrent
//
//  Created by 杨磊 on 15/8/29.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import "IdentityScope.h"

@interface IdentityScope()

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSLock *myLock;

@end

@implementation IdentityScope

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dictionary = [[NSMutableDictionary alloc] init];
        _myLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)lock
{
    [self.myLock lock];
}

- (void)unlock
{
    [self.myLock unlock];
}

- (id)objectByKey:(id)key lock:(BOOL)lock
{
    id ret = nil;
    if (lock)
        [self lock];
    ret = [self.dictionary objectForKey:key];
    if (lock)
        [self unlock];
    return ret;
}

- (id)objectByCondition:(BOOL (^)(id, id))condition lock:(BOOL)lock
{
    id ret = nil;
    if (lock)
        [self lock];
    NSArray *keys = [self.dictionary allKeys];
    for (NSInteger index = 0; index < [keys count]; ++ index)
    {
        id key = [keys objectAtIndex:index];
        if (condition && condition(key, [self.dictionary objectForKey:key]))
        {
            ret = [self.dictionary objectForKey:key];
            break;
        }
    }
    
    if (lock)
        [self unlock];
    return ret;
}

- (void)appendObject:(id)object key:(id)key lock:(BOOL)lock
{
    if (!key || !object) return;
    if (lock)
        [self lock];
    [self.dictionary setObject:object forKey:key];
    
    if (lock)
        [self unlock];
}

- (void)clear
{
    [self lock];
    [self.dictionary removeAllObjects];
    [self unlock];
}

- (void)removeObjectForKey:(id)key lock:(BOOL)lock
{
    if (lock)
        [self lock];
    [self.dictionary removeObjectForKey:key];
    if (lock)
        [self unlock];
}

@end
