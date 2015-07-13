//
//  CacheManagerTool.m
//  BJEducation_student
//
//  Created by Mrlu-bjhl on 15/1/5.
//  Copyright (c) 2015年 Baijiahulian. All rights reserved.
//

#import "BJCacheManagerTool.h"
#import <SDWebImage/SDWebImageManager.h>

#import "BJFileManagerTool.h"

@implementation BJCacheManagerTool

#pragma mark - video
-(void)clearVideosFiles
{
    NSString *tmpDir = NSTemporaryDirectory();
    tmpDir = [tmpDir stringByAppendingString:@"Videos"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if([fileManager removeItemAtPath:tmpDir error:&error])
    {
        NSLog(@"%@下文件删除成功",tmpDir);
    }
    else
    {
        NSLog(@"%@下文件删除失败:error:%@",tmpDir,error.description);
    }
}

//获取本地文件名
- (NSString *)getVideoFileSavePath:(NSString *)filename
{
    NSString *tmpDir = NSTemporaryDirectory();
    tmpDir = [tmpDir stringByAppendingString:@"Videos"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:tmpDir isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        if(!bCreateDir){
            NSLog(@"Create Video Directory Failed.");
        }
        NSLog(@"%@",tmpDir);
    }
    
    NSString *path = [tmpDir stringByAppendingPathComponent:filename];
    NSLog(@"Video Path:%@",path);
    return path;
}

#pragma mark - audio
//获取本地文件名
- (NSString *)getAudioFileSavePath:(NSString *)filename
{
    NSString *tmpDir = NSTemporaryDirectory();
    tmpDir = [tmpDir stringByAppendingString:@"Audios"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:tmpDir isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        if(!bCreateDir){
            NSLog(@"Create Audios Directory Failed.");
        }
        NSLog(@"%@",tmpDir);
    }
    
    NSString *path = [tmpDir stringByAppendingPathComponent:filename];
    NSLog(@"Audios Path:%@",path);
    return path;
}

//清楚音频文件
- (void)clearAudioFiles
{
    NSString *tmpDir = NSTemporaryDirectory();
    tmpDir = [tmpDir stringByAppendingString:@"Audios"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if([fileManager removeItemAtPath:tmpDir error:&error])
    {
        NSLog(@"%@下文件删除成功",tmpDir);
    }
    else
    {
        NSLog(@"%@下文件删除失败:error:%@",tmpDir,error.description);
    }
}


#pragma mark - all
- (void)clearCacheWithSuccess:(void(^)(void))success
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //片头片尾
        [self clearVideosFiles];
        
        //清楚老师优化说文件
        [self clearAudioFiles];
        
        //图片缓存
        [[SDWebImageManager sharedManager].imageCache clearMemory];
        [[SDWebImageManager sharedManager].imageCache clearDiskOnCompletion:^{
            NSLog(@"images清理完成");
        }];
       dispatch_async(dispatch_get_main_queue(), ^{
           if (success) {
               success();
           }
       });
    });
}

- (CGFloat)getCacheFileSize
{
    CGFloat fileSize = 0;
    
    //videos
    NSString *tmpDir = NSTemporaryDirectory();
    tmpDir = [tmpDir stringByAppendingString:@"Videos"];
    
    //Audios
    NSString *tmpDir1 = NSTemporaryDirectory();
    tmpDir1 = [tmpDir1 stringByAppendingString:@"Audios"];

    fileSize += [BJFileManagerTool folderSizeAtPath:tmpDir];
    fileSize += [BJFileManagerTool folderSizeAtPath:tmpDir1];
    
    fileSize += [[SDWebImageManager sharedManager].imageCache getSize]/(1024.0*1024.0);
    
    return fileSize;
}

- (void)getCacheFileSize:(void (^)(CGFloat))finish{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 耗时的操作
        CGFloat fileSize = 0;
        
        //videos
        NSString *tmpDir = NSTemporaryDirectory();
        tmpDir = [tmpDir stringByAppendingString:@"Videos"];
        
        //Audios
        NSString *tmpDir1 = NSTemporaryDirectory();
        tmpDir1 = [tmpDir1 stringByAppendingString:@"Audios"];
        
        fileSize += [BJFileManagerTool folderSizeAtPath:tmpDir];
        fileSize += [BJFileManagerTool folderSizeAtPath:tmpDir1];
        
        fileSize += [[SDWebImageManager sharedManager].imageCache getSize]/(1024.0*1024.0);
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新界面
            if (finish) {
                finish(fileSize);
            }
        });
    });

    
}

@end
