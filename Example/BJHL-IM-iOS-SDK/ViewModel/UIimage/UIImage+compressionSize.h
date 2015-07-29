//
//  UIImage+limitSizeData.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/29.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (compressionSize)
/**
 *  根据传入的size压缩返回一个符合要求的data数据
 *
 *  @param size 最大的大小，单位m
 *
 *  @return jpg格式的data数据
 */
- (NSData *)bj_jpgDataWithCompressionSize:(long long)size;
@end
