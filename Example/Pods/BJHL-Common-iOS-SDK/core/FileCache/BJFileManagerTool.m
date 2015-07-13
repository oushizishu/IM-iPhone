//
//  FileManagerTool.m
//  BJEducation_student
//
//  Created by Mrlu-bjhl on 15/1/19.
//  Copyright (c) 2015年 Baijiahulian. All rights reserved.
//

#import "BJFileManagerTool.h"

@implementation BJFileManagerTool

/*获取沙盒主目录路径*/
+ (NSString *)homeDir{
    NSString *homeDir = NSHomeDirectory();
    return homeDir;
}

/*app路径*/
+ (NSString *)appDir
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

/*获取Documents目录路径*/
+ (NSString *)docDir{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    return docDir;
}

/*Library*/
+ (NSString *)libraryDir{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

/*Library/Preference*/
+ (NSString *)libPrefDir
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingFormat:@"/Preference"];
}

/*获取Caches目录路径*/
+ (NSString *)cachesDir{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    return cachesDir;
}

/*获取tmp目录路径*/
+ (NSString *)tmpDir {
    NSString *tmpDir =  NSTemporaryDirectory();
    return tmpDir;
}

/*文件是否存在*/
+ (BOOL)isFileExisted:(NSString *)fileName path:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]){
        return NO;
    }
    return YES;
}

/*创建指定名字的文件*/
+ (BOOL)createFile:(NSString *)fileName path:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]){
        [fileManager createFileAtPath:path contents:nil attributes:nil];
        return YES;
    }
    return NO;
}

/*创建指定名字的文件夹*/
+ (BOOL)createDirectory:(NSString *)folder path:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]){
        NSError *error = nil;
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        return YES;
    }
    return NO;
}

/*得到文件路径*/
+ (NSString *)getFile:(NSString *)fileName path:(NSString *)path{
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    return filePath;
}

/*删除文件*/
+ (BOOL)deleteFile:(NSString *)fileName path:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]){
        return NO;
    }
    [fileManager removeItemAtPath:path error:nil];
    return YES;
}

/*得到资源路径*/
- (NSString *)pathForBundleResource:(NSString *)name ofType:(NSString *)ext
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:name ofType:ext];
    return path;
}

/*得到资源路径*/
+ (NSString *)pathForBundleResource:(NSString *)name ofType:(NSString *)ext inDirectory:(NSString *)subpath {
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:name ofType:ext inDirectory:subpath];
    return path;
}

//遍历文件夹获得文件夹大小，返回多少M
+ (float)folderSizeAtPath:(NSString*) folderPath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}

//单个文件的大小
+ (long long) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

@end
