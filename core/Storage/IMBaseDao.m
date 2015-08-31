//
//  IMBaseDao.m
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import "IMBaseDao.h"

@implementation IMBaseDao

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _identityScope = [[IdentityScope alloc] init];
    }
    return self;
}

- (void)attachEntityKey:(id)key entity:(id)entity lock:(BOOL)lock
{
    [self.identityScope appendObject:entity key:key lock:lock];
}

- (void)detach:(id)key
{
    [self detach:key lock:YES];
}

- (void)detach:(id)key lock:(BOOL)lock
{
    [self.identityScope removeObjectForKey:key lock:lock];
}

- (void)clear
{
    [self.identityScope clear];
}
@end
