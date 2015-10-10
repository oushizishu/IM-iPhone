//
//  ZoomingScrollView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "BJPictureCommon.h"
#import "BJZoomingScrollView.h"
#import "BJPictueBrowser.h"
#import "BJPicture.h"
#import "DALabeledCircularProgressView.h"
#import "BJPictureBrowserPrivate.h"
#import "BJCommonDefines.h"
#import "TKActionSheetController.h"
#import "UIView+Basic.h"

// Private methods and properties
@interface BJZoomingScrollView () {
    
	BJTapDetectingView *_tapView; // for background taps
	DALabeledCircularProgressView *_loadingIndicator;
    UIImageView *_loadingError;
    BOOL _isDisplayingImage;
    
}

@property (nonatomic, strong, readwrite) BJTapDetectingImageView *photoImageView;

@end

@implementation BJZoomingScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        // Setup
        _index = NSUIntegerMax;

        _isDisplayingImage = NO;
        
		// Tap view for background
		_tapView = [[BJTapDetectingView alloc] initWithFrame:self.bounds];
		_tapView.tapDelegate = self;
		_tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tapView.backgroundColor = [UIColor blackColor];
		[self addSubview:_tapView];
		
		// Image view
		_photoImageView = [[BJTapDetectingImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.tapDelegate = self;
        _photoImageView.clipsToBounds = YES;
        _photoImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		_photoImageView.contentMode = UIViewContentModeScaleAspectFill;
		_photoImageView.backgroundColor = [UIColor clearColor];
		[self addSubview:_photoImageView];
		
		// Loading indicator
		_loadingIndicator = [[DALabeledCircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
        _loadingIndicator.innerTintColor = [UIColor colorWithWhite:150/255.0 alpha:0.8];
        _loadingIndicator.trackTintColor = [UIColor colorWithWhite:100/255.0 alpha:0.8];
        _loadingIndicator.progressTintColor = [UIColor whiteColor];
        _loadingIndicator.progressLabel.font = [UIFont systemFontOfSize:12];
        _loadingIndicator.progressLabel.textColor = [UIColor whiteColor];
        _loadingIndicator.userInteractionEnabled = NO;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) {
            _loadingIndicator.thicknessRatio = 0.2;
            _loadingIndicator.roundedCorners = NO;
        } else {
            _loadingIndicator.thicknessRatio = 0.3;
            _loadingIndicator.roundedCorners = YES;
        }
        _loadingIndicator.backgroundColor = [UIColor clearColor];
		_loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:_loadingIndicator];
        
		// Setup
		self.backgroundColor = [UIColor blackColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    self.imageDidLoadBlock = nil;
    [self hideImageFailure];
    self.photo = nil;
    self.thumbPhoto = nil;
    self.captionView = nil;
    self.selectedButton = nil;
    _photoImageView.image = nil;
    _isDisplayingImage = NO;
    _index = NSUIntegerMax;
}
#pragma mark - Image

- (void)setThumbPhoto:(id<BJPicture>)thumbPhoto {
    if (_photo) {
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
    }
    _thumbPhoto = thumbPhoto;
    
    weakifyself;
    [thumbPhoto loadUnderlyingImageOnlyLocal:YES
                                    progress:nil
                                   completed:^(UIImage *image, NSError *error, BOOL finished) {
                                       strongifyself;
                                       if (image) {
                                           if (image) {
                                               // Successful load
                                               [self displayThumbImage];
                                           }
                                       }
                                   }];

}

- (void)setPhoto:(id<BJPicture>)photo {
    // Cancel any loading on old photo
    if (_photo && photo == nil) {
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
    }
    _photo = photo;
    
    [self showLoadingIndicator];
    
    weakifyself;
    weakifyobject(photo);
    [photo loadUnderlyingImageProgress:^(CGFloat process) {
        strongifyself;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setProgress:process];

        });
    } completed:^(UIImage *image, NSError *error, BOOL finished) {
        strongifyself;
        strongifobject(photo);
        if (image) {
            // Successful load
            [self displayImage];
            if (self.imageDidLoadBlock) {
                self.imageDidLoadBlock(self,photo);
            }
        } else {
            // Failed to load
            [self displayImageFailure];
        }
    }];

}

// Get and display image
- (void)displayImage {
	if (_photo && !_isDisplayingImage) {
		
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
		
		// Get image from browser as it handles ordering of fetching
		UIImage *img = [_photo underlyingImage];
		if (img) {
            _isDisplayingImage = YES;
            
            BOOL isDisplayThumb = ([_thumbPhoto underlyingImage] && [_thumbPhoto underlyingImage] == _photoImageView.image);
            
			// Hide indicator
			[self hideLoadingIndicator];
			
			// Set image
			_photoImageView.image = img;
			_photoImageView.hidden = NO;
            
            CGRect orignFrame = _photoImageView.frame;
			
			// Setup photo frame
            
            CGSize boundsSize = self.bounds.size;
            CGSize imageSize = img.size;
            
            
            CGFloat frameScale = 1;
            if (imageSize.width > boundsSize.width || imageSize.height > boundsSize.height) {
                // Calculate Min
                CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
                CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
                frameScale = MIN(xScale, yScale);
            }
            
            imageSize.width = imageSize.width * frameScale;
            imageSize.height = imageSize.height * frameScale;
            
            self.minimumZoomScale = 1;
            
            // Calculate Max
            CGFloat maxScale = 3;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                // Let them go a bit bigger on a bigger screen!
                maxScale = 4;
            }
            self.maximumZoomScale =  maxScale/frameScale;
            
            CGRect photoImageViewFrame;
            photoImageViewFrame.origin = CGPointZero;
            photoImageViewFrame.size = imageSize;
            
            self.contentSize = photoImageViewFrame.size;
            
            
			// Set zoom to minimum zoom
            // Horizontally
            if (photoImageViewFrame.size.width < boundsSize.width) {
                photoImageViewFrame.origin.x = floorf((boundsSize.width - photoImageViewFrame.size.width) / 2.0);
            } else {
                photoImageViewFrame.origin.x = 0;
            }
            
            // Vertically
            if (photoImageViewFrame.size.height < boundsSize.height) {
                photoImageViewFrame.origin.y = floorf((boundsSize.height - photoImageViewFrame.size.height) / 2.0);
            } else {
                photoImageViewFrame.origin.y = 0;
            }
            
            
            if (isDisplayThumb) {
                _photoImageView.frame = orignFrame;
                
                [UIView animateWithDuration:0.4 animations:^{
                    _photoImageView.frame = photoImageViewFrame;
                } completion:^(BOOL finished) {
                    
                }];
            } else {
                _photoImageView.frame = photoImageViewFrame;
            }
		} else {
            self.contentSize = CGSizeMake(0, 0);
            
			// Failed no image
            if (!_photoImageView.image) {
                [self displayImageFailure];
            }
		}
		[self setNeedsLayout];
	}
}

- (void)adjustMaxMinZoomScalesForCurrentBounds {
    if (_isDisplayingImage) {
        // Set image
        
        CGRect orignFrame = _photoImageView.frame;
        
        // Setup photo frame
        
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        
        
        CGFloat frameScale = 1;
        if (imageSize.width > boundsSize.width || imageSize.height > boundsSize.height) {
            // Calculate Min
            CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
            CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
            frameScale = MIN(xScale, yScale);
        }
        
        imageSize.width = imageSize.width * frameScale;
        imageSize.height = imageSize.height * frameScale;
        
        self.minimumZoomScale = 1;
        
        // Calculate Max
        CGFloat maxScale = 3;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            // Let them go a bit bigger on a bigger screen!
            maxScale = 4;
        }
        self.maximumZoomScale =  maxScale/frameScale;
        
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = imageSize;
        
        self.contentSize = photoImageViewFrame.size;
        
        
        // Set zoom to minimum zoom
        // Horizontally
        if (photoImageViewFrame.size.width < boundsSize.width) {
            photoImageViewFrame.origin.x = floorf((boundsSize.width - photoImageViewFrame.size.width) / 2.0);
        } else {
            photoImageViewFrame.origin.x = 0;
        }
        
        // Vertically
        if (photoImageViewFrame.size.height < boundsSize.height) {
            photoImageViewFrame.origin.y = floorf((boundsSize.height - photoImageViewFrame.size.height) / 2.0);
        } else {
            photoImageViewFrame.origin.y = 0;
        }
        _photoImageView.frame = photoImageViewFrame;
    }
}

- (void)displayThumbImage {
    if (_thumbPhoto && _photoImageView.image == nil) {
        
        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);
        
        // Get image from browser as it handles ordering of fetching
        UIImage *img = [_thumbPhoto underlyingImage];
        if (img) {
            
            [self hideImageFailure];
            
            // Set image
            _photoImageView.image = img;
            _photoImageView.hidden = NO;
            
            CGSize boundsSize = self.bounds.size;
            
            // Setup photo frame
            CGRect photoImageViewFrame;
            CGFloat width = (self.current_w - 10)/4.;
            
            CGSize imageSize = img.size;
            CGFloat frameScale = 1;
            if (imageSize.width > boundsSize.width || imageSize.height > boundsSize.height) {
                // Calculate Min
                CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
                CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
                frameScale = MIN(xScale, yScale);
            }
            
            imageSize.width = imageSize.width * frameScale;
            imageSize.height = imageSize.height * frameScale;
                        
            photoImageViewFrame.origin = CGPointZero;
            photoImageViewFrame.size = imageSize;
            
            // Horizontally
            if (photoImageViewFrame.size.width < boundsSize.width) {
                photoImageViewFrame.origin.x = floorf((boundsSize.width - photoImageViewFrame.size.width) / 2.0);
            } else {
                photoImageViewFrame.origin.x = 0;
            }
            
            // Vertically
            if (photoImageViewFrame.size.height < boundsSize.height) {
                photoImageViewFrame.origin.y = floorf((boundsSize.height - photoImageViewFrame.size.height) / 2.0);
            } else {
                photoImageViewFrame.origin.y = 0;
            }
            
            _photoImageView.frame = photoImageViewFrame;
            self.contentSize = photoImageViewFrame.size;
            
        }
        [self setNeedsLayout];
    }
}


// Image failed so just show black!
- (void)displayImageFailure {
    [self hideLoadingIndicator];
    if (_photoImageView.image) {
        return;
    }
    _photoImageView.image = nil;
    if (!_loadingError) {
        _loadingError = [UIImageView new];
        _loadingError.image = [UIImage imageNamed:@"MWPhotoBrowser.bundle/images/ImageError.png"];
        _loadingError.userInteractionEnabled = NO;
		_loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [_loadingError sizeToFit];
        [self addSubview:_loadingError];
    }
    _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                     floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                                     _loadingError.frame.size.width,
                                     _loadingError.frame.size.height);
}

- (void)hideImageFailure {
    if (_loadingError) {
        [_loadingError removeFromSuperview];
        _loadingError = nil;
    }
}

#pragma mark - Loading Progress

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    _loadingIndicator.progress = MAX(MIN(1, progress), 0);
    _loadingIndicator.progressLabel.text = [NSString stringWithFormat:@"%.0f%%", progress*100];

}

- (void)hideLoadingIndicator {
    _loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator {
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    _loadingIndicator.progress = 0;
    _loadingIndicator.hidden = NO;
    _loadingIndicator.progressLabel.text = [NSString stringWithFormat:@"%d%%", 0];
    [self hideImageFailure];
}

#pragma mark - Layout

- (void)layoutSubviews {
	
	// Update tap view frame
	_tapView.frame = self.bounds;
	
	// Position indicators (centre does not seem to work!)
	if (!_loadingIndicator.hidden)
        _loadingIndicator.frame = CGRectMake(floorf((self.bounds.size.width - _loadingIndicator.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingIndicator.frame.size.height) / 2),
                                         _loadingIndicator.frame.size.width,
                                         _loadingIndicator.frame.size.height);
	if (_loadingError)
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                                         _loadingError.frame.size.width,
                                         _loadingError.frame.size.height);

	// Super
	[super layoutSubviews];
//    
    
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.scrollEnabled = YES; // reset
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
        _photoImageView.frame = frameToCenter;
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    [_photoBrowser dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
	
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
	
	// Zoom
	if (self.zoomScale != self.minimumZoomScale) {
		
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
		
	} else {
		
		// Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];

	}
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UIGestureRecognizer *)gest {
    [self handleSingleTap:[gest locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UIGestureRecognizer *)gest {
    [self handleDoubleTap:[gest locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView longPressDetected:(UIGestureRecognizer *)gest
{
    TKActionSheetController *actionSheet = [[TKActionSheetController alloc] initWithTitle:nil];
    [actionSheet addButtonWithTitle:@"保存" handler:^{
        [_photoBrowser savePhoto];
    }];
    [actionSheet setCancelButtonWithTitle:@"取消" handler:nil];
    [actionSheet showInViewController:_photoBrowser animated:YES completion:nil];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UIGestureRecognizer *)gest {
    // Translate touch location to image view location
    CGFloat touchX = [gest locationInView:view].x;
    CGFloat touchY = [gest locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view doubleTapDetected:(UIGestureRecognizer *)gest {
    // Translate touch location to image view location
    CGFloat touchX = [gest locationInView:view].x;
    CGFloat touchY = [gest locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view longPressDetected:(UIGestureRecognizer *)gest
{
    TKActionSheetController *actionSheet = [[TKActionSheetController alloc] init];
    [actionSheet addButtonWithTitle:@"保存" handler:^{
        [_photoBrowser savePhoto];
    }];
    [actionSheet setCancelButtonWithTitle:@"取消" handler:nil];
    [actionSheet showInViewController:_photoBrowser animated:YES completion:nil];
}
@end
