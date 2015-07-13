//
//  CacheManagerTool.h
//  BJEducation_student
//
//  Created by Mrlu-bjhl on 15/1/5.
//  Copyright (c) 2015年 Baijiahulian. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  本地文件缓存
 */
@interface BJCacheManagerTool : NSObject

#pragma cache 图片、视频、音频
- (void)clearCacheWithSuccess:(void(^)(void))success;

#pragma mark - video
-(void)clearVideosFiles;
- (NSString *)getVideoFileSavePath:(NSString *)filename;

#pragma mark - audio
- (void)clearAudioFiles;
- (NSString *)getAudioFileSavePath:(NSString *)filename;

/**
 *  sync 同步
 *
 *  @return <#return value description#>
 */
- (CGFloat)getCacheFileSize;
/**
 *
 * Async 异步
 *  @param finish <#finish description#>
 */
- (void)getCacheFileSize:(void(^)(CGFloat size))finish;

@end
