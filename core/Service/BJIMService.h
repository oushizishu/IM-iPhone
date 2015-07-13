//
//  BJIMService.h
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import <Foundation/Foundation.h>

@interface BJIMService : NSObject

- (void)startService;

- (void)stopService;

- (void)applicationEnterBackground;
- (void)applicationEnterForeground;
@end
