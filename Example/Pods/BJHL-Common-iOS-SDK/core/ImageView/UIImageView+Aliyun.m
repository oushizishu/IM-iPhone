//
//  UIImageView+Aliyun.m
//  BJEducation
//
//  Created by hushichao on 2/3/15.
//  Copyright (c) 2015 com.bjhl. All rights reserved.
//

#import "UIImageView+Aliyun.h"
#import "UIImageView+WebCache.h"

@implementation UIImageView (Aliyun)

- (void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder{
    [self setAliyunImageWithURL:url placeholderImage:placeholder size:self.frame.size];
}

- (void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder size:(CGSize)size
{
    self.contentMode = UIViewContentModeScaleAspectFill;
    [self setAliyunImageWithURL:url placeholderImage:placeholder size:size cut:false];
}

-(void)setAliyunImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder size:(CGSize)size cut:(BOOL)cut{
    if (url && ![url isFileURL]){
        NSInteger w = (NSInteger)size.width;
        NSInteger h = (NSInteger)size.height;
        NSString *param = [NSString stringWithFormat:@"@%ldw_%ldh_1o", (long)w, (long)h];
        
        NSInteger scale = (NSInteger)[UIScreen mainScreen].scale;
        if (scale > 1){
            param = [param stringByAppendingFormat:@"_%ldx", (long)scale];
        }
        if (cut){
            //改为短边优先进行裁剪
            param = [param stringByAppendingFormat:@"_1e_1c"];
        }
        /*
        if (radius){
            param = [param stringByAppendingFormat:@"_%ld-2ci", (long)radius];
        }*/
        
        NSRange r = [url.absoluteString rangeOfString:@"?"];
        if (r.location == NSNotFound){
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", url.absoluteString, param]];
        } else {
            NSString *urlStr = [NSString stringWithFormat:@"%@%@?%@", [url.absoluteString substringToIndex:r.location], param, [url.absoluteString substringFromIndex:r.location]];
            url = [NSURL URLWithString:urlStr];
        }
        [self sd_setImageWithURL:url placeholderImage:placeholder options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
        }];
    }
    else if ([url isFileURL])
    {
        [self setImage:[UIImage imageWithContentsOfFile:[url relativePath]]];
    }
    else{
        [self setImage:placeholder];
    }
   
    
    
    
    
}

@end
