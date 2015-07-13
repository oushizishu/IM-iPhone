//
//  UIView+line.h
//  BJEducation_student
//
//  Created by Mrlu-bjhl on 14-9-18.
//  Copyright (c) 2014年 Baijiahulian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (line)

+ (UIView *)lineWithColor:(UIColor *)color frame:(CGRect)frame;

+ (UIView *)lineWithColor:(UIColor *)color size:(CGSize)size;

+ (UIView *)graylineWithFrame:(CGRect)frame;

+ (UIView *)graylineWithSize:(CGSize)size;

+ (UIView *)graylineWithWidth:(CGFloat)width;


@end
