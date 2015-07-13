//
//  BJIMService.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "BJIMService.h"
#import "BJIMEngine.h"
#import "BJIMStorage.h"

@interface BJIMService()

@property (nonatomic, strong) BJIMEngine *imEngine;
@property (nonatomic, strong) BJIMStorage *imStorage;
@property (nonatomic, assign) BOOL bIsServiceActive;

@end

@implementation BJIMService

- (void)startService
{
    self.bIsServiceActive = YES;
}

- (void)stopService
{
    self.bIsServiceActive = NO;
}


- (void)applicationEnterForeground
{
    [self.imEngine start];
}

- (void)applicationEnterBackground
{
    [self.imEngine stop];
}

#pragma mark - Setter & Getter
- (BJIMEngine *)imEngine
{
    if (_imEngine == nil)
    {
        _imEngine = [[BJIMEngine alloc] init];
    }
    return _imEngine;
}

- (BJIMStorage *)imStorage
{
    if (_imStorage == nil)
    {
        _imStorage = [[BJIMStorage alloc] init];
    }
    return _imStorage;
}

- (BOOL)bIsServiceActive
{
    return _bIsServiceActive;
}
@end
