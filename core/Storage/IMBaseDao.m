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
    [self.identityScope removeObjectForKey:key];
}

- (void)clear
{
    [self.identityScope clear];
}
@end
