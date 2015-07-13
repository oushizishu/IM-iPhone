//
//  ZoomingScrollView.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BJPictureProtocol.h"
#import "BJTapDetectingImageView.h"
#import "BJTapDetectingView.h"

@class BJPictueBrowser, BJPicture, BJCaptionView;

@interface BJZoomingScrollView : UIScrollView <UIScrollViewDelegate, BJTapDetectingImageViewDelegate, BJTapDetectingViewDelegate> {

}

@property () NSUInteger index;
@property (nonatomic) id <BJPicture> photo;
@property (nonatomic) id <BJPicture> thumbPhoto;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong, readonly) BJTapDetectingImageView *photoImageView;
@property (nonatomic, weak) BJCaptionView *captionView;
@property (nonatomic, weak) UIButton *selectedButton;
@property (nonatomic, weak) BJPictueBrowser *photoBrowser;

@property (nonatomic, copy) void(^imageDidLoadBlock)(BJZoomingScrollView *page,id<BJPicture> picture);

- (void)displayThumbImage;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)displayImage;
- (void)adjustMaxMinZoomScalesForCurrentBounds;
- (void)displayImageFailure;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end
