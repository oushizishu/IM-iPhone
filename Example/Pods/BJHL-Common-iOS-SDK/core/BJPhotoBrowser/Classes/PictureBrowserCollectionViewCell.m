//
//  PictureBrowserCollectionViewCell.m
//  BJEducation_student
//
//  Created by Mac_ZL on 15/5/18.
//  Copyright (c) 2015年 Baijiahulian. All rights reserved.
//

#import "PictureBrowserCollectionViewCell.h"
#import "BJZoomingScrollView.h"
@implementation PictureBrowserCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _zoomView = [[BJZoomingScrollView alloc] initWithFrame:CGRectInset(self.bounds, PADDING + 2, 0)];
        _zoomView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_zoomView];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_zoomView prepareForReuse];
}

- (void)setBrowser:(BJPictueBrowser *)browser
{
    _browser = browser;
    [_zoomView setPhotoBrowser:_browser];
}
- (void)setPhoto:(id<BJPicture>)photo
{
    _photo = photo;
    [_zoomView setPhoto:photo];
}
- (void)setThumbPhoto:(id<BJPicture>)thumbPhoto
{
    _thumbPhoto = thumbPhoto;
    [_zoomView setThumbPhoto:thumbPhoto];
    
}
- (void)setMaxMinZoomScalesForCurrentBounds
{
    [_zoomView setMaxMinZoomScalesForCurrentBounds];
}
- (void)displayThumbImage
{
    [_zoomView displayThumbImage];
}
- (void)displayImage
{
    [_zoomView displayImage];
}
- (void)displayImageFailure;
{
    [_zoomView displayImageFailure];
}

- (void)setImageDidLoadBlock:(void (^)(PictureBrowserCollectionViewCell *, id<BJPicture>))imageDidLoadBlock {
//    weakifyself;
//    [_zoomView setImageDidLoadBlock:^(id<BJPicture> picture) {
//        strongifyself;
//        if (imageDidLoadBlock) {
//            imageDidLoadBlock(self, picture);
//        }
//    }];
}

@end
