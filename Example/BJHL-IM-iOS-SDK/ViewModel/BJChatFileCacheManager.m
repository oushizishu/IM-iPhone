//
//  BJFileCacheManager.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/29.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatFileCacheManager.h"

#define BJChatFile_RootPath @"Chat"
#define BJChatFile_Audio @"Audio"
#define BJChatFile_Images @"Images"

@implementation BJChatFileCacheManager

+ (void)createDir:(NSString *)path
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSAssert2(0, @"%s 创建目录失败 [path:%@]", __FUNCTION__,path);
        }
    }
}

+ (void)initialize
{
    [BJChatFileCacheManager createDir:[self chatRootPath]];
    [BJChatFileCacheManager createDir:[self chatImagesPath]];
    [BJChatFileCacheManager createDir:[self chatAudiosPath]];
}

+ (NSString *)chatRootPath;
{
    return [BJCachesDir stringByAppendingPathComponent:BJChatFile_RootPath];
}

+ (NSString *)chatImagesPath;
{
    return [[self chatRootPath] stringByAppendingPathComponent:BJChatFile_Images];
}
+ (NSString *)chatAudiosPath;
{
    return [[self chatRootPath] stringByAppendingPathComponent:BJChatFile_Audio];
}

+ (NSString *)imageCachePathWithName:(NSString *)imageName;
{
    if (imageName.length<=0) {
        NSAssert(0, @"图片名称不能为空");
        return nil;
    }
    return [[self chatImagesPath] stringByAppendingPathComponent:imageName];
}
+ (NSString *)audioCachePathWithName:(NSString *)audioName;
{
    if (audioName.length<=0) {
        NSAssert(0, @"音频名称不能为空");
        return nil;
    }
    return [[self chatAudiosPath] stringByAppendingPathComponent:audioName];

}

#pragma mark - 生成名称
+ (NSString *)generateJpgImageName;
{
    @TODO("可以优化，data一样的话生成一样的名称");
    return [NSString stringWithFormat:@"image_%.f.jpg",[NSDate timeIntervalSinceReferenceDate]];
}

+ (NSString *)generateMp3AudioName;
{
    return [NSString stringWithFormat:@"audio_%.f.mp3",[NSDate timeIntervalSinceReferenceDate]];
 
}


@end
