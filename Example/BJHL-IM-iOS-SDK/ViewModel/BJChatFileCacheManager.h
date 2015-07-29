//
//  BJFileCacheManager.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/29.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJFileManagerTool.h>
@interface BJChatFileCacheManager : NSObject
+ (NSString *)chatRootPath;
+ (NSString *)chatAudiosPath;
+ (NSString *)chatImagesPath;

+ (NSString *)imageCachePathWithName:(NSString *)imageName;
+ (NSString *)audioCachePathWithName:(NSString *)audioName;

+ (NSString *)generateJpgImageName;
+ (NSString *)generateMp3AudioName;
@end
