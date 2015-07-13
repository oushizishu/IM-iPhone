//
//  UIImageView+Aliyun.h
//  BJEducation
//
//  Created by hushichao on 2/3/15.
//  Copyright (c) 2015 com.bjhl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Aliyun)

//如果使用的autolayout，viewDidLoad的时候imageView还没有frame，这时候不能使用这个方法，必须手动传size进去
- (void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

- (void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder size:(CGSize)size;

//cut为true，则短边优先进行裁剪； 否则，按长边优先，其他地方留白
-(void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder size:(CGSize)size cut:(BOOL)cut;

@end
