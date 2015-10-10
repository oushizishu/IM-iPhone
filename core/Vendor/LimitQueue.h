//
//  LimitQueue.h
//  Pods
//
//  Created by 杨磊 on 15/9/18.
//
//

#import <Foundation/Foundation.h>

/**
 *  限长队列
 */
@interface LimitQueue : NSObject

- (instancetype)initWithCapacity:(NSInteger)capacity;

@property (nonatomic, assign, readonly) NSInteger capacity;

/**
 *  入队
 *
 *  @return <#return value description#>
 */
- (BOOL)offer:(id)object;

/**
 *  出队
 *
 *  @return <#return value description#>
 */
- (id)poll;

- (NSArray *)toArray;
@end
