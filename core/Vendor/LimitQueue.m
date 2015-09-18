//
//  LimitQueue.m
//  Pods
//
//  Created by 杨磊 on 15/9/18.
//
//

#import "LimitQueue.h"

@interface LimitQueue()

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation LimitQueue

- (instancetype)init
{
    return [self initWithCapacity:10];
}

- (instancetype)initWithCapacity:(NSInteger)capacity
{
    self = [super init];
    if (self)
    {
        _capacity = capacity;
        _array = [[NSMutableArray alloc] initWithCapacity:capacity];
    }
    return self;
}


- (BOOL)offer:(id)object
{
    [_array addObject:object];
    while ([_array count] > _capacity) {
        [self poll];
    }
    return YES;
}

- (id)poll
{
    NSInteger count = _array.count;
    if (count == 0) return nil;
    
    id rst = [_array objectAtIndex:0];
    [_array removeObjectAtIndex:0];
    return rst;
}

- (NSArray *)toArray
{
    return [NSArray arrayWithArray:_array];
}
@end
