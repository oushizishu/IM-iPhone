
#import "BJTimer.h"
@implementation BJTimer

-(void)time
{
    if ([target respondsToSelector:selector]) {
        [target performSelector:selector];
    }
}

- (void)dealloc
{
    [self invalidate];
}

- (void)invalidate
{
    [self.timer invalidate];
    _timer = nil;
    target = nil;
    selector = nil;
}
+ (BJTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector forMode:(NSString *)mode
{
    BJTimer* timer = [[BJTimer alloc] init];
    if (timer)
    {
        timer->target = aTarget;
        timer->selector = aSelector;
        timer.timer = [NSTimer timerWithTimeInterval:ti target:timer selector:@selector(time) userInfo:nil repeats:YES];
        NSRunLoop *runner = [NSRunLoop currentRunLoop];
        [runner addTimer: timer.timer forMode:mode];
    }
    return timer;
}
@end
