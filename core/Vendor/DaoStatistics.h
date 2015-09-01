//
// Dao 层的统计分析 </br>
// 统计目标:
//    1、上层发起过多少次 DB 操作， 动作是什么
//    2、 命中过多少次缓存。
//    3、比较两个数据，得出优化度
//
//
//  DaoStatistics.h
//  Pods
//
//  Created by 杨磊 on 15/9/1.
//
//

#import <Foundation/Foundation.h>

@interface DaoStatistics : NSObject

+ (instancetype)sharedInstance;

- (void)logDBOperationSQL:(NSString *)sql class:(__unsafe_unretained Class)clazz;

- (void)logDBCacheSQL:(NSString *)sql class:(__unsafe_unretained Class)clazz;

- (void)statistics;

@end
