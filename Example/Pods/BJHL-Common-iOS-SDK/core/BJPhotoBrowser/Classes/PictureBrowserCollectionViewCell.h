//
//  PictureBrowserCollectionViewCell.h
//  BJEducation_student
//
//  Created by Mac_ZL on 15/5/18.
//  Copyright (c) 2015年 Baijiahulian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJPictureProtocol.h"
#import "BJPictureCommon.h"
@class BJZoomingScrollView;
@class BJCaptionView;
@class BJPictueBrowser;
@interface PictureBrowserCollectionViewCell : UICollectionViewCell

@property (nonatomic,strong) BJZoomingScrollView  *zoomView;
@property (nonatomic,assign) NSInteger index;
@property (nonatomic) id <BJPicture> photo;
@property (nonatomic) id <BJPicture> thumbPhoto;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, weak) BJCaptionView *captionView;
@property (nonatomic, weak) UIButton *selectedButton;
@property (nonatomic,assign) BJPictueBrowser *browser;

@property (nonatomic, copy) void(^imageDidLoadBlock)(PictureBrowserCollectionViewCell *cell, id<BJPicture> picture);

- (void)displayImage;
- (void)displayImageFailure;
- (void)displayThumbImage;
- (void)setMaxMinZoomScalesForCurrentBounds;
@end
