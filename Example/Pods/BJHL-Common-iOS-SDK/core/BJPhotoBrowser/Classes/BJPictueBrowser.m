//
//  MWPhotoBrowser.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BJPictureCommon.h"
#import "BJPictueBrowser.h"
#import "BJPictureBrowserPrivate.h"
#import "SDImageCache.h"
#import "BJPictureZoomAnimator.h"
#import "PictureBrowserCollectionViewCell.h"
#import "BJCommonDefines.h"

#define ACTION_SHEET_OLD_ACTIONS 2000

@implementation BJPictueBrowser

#pragma mark - Init

- (id)init {
    if ((self = [super init])) {
        [self _initialisation];
    }
    return self;
}

- (id)initWithDelegate:(id <BJPictureBrowserDelegate>)delegate {
    if ((self = [self init])) {
        _delegate = delegate;
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self _initialisation];
    }
    return self;
}

- (void)_initialisation {
    
    // Defaults
    NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (isVCBasedStatusBarAppearanceNum) {
        _isVCBasedStatusBarAppearance = isVCBasedStatusBarAppearanceNum.boolValue;
    } else {
        _isVCBasedStatusBarAppearance = YES; // default
    }
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if (SYSTEM_VERSION_LESS_THAN(@"7")) self.wantsFullScreenLayout = YES;
#endif
    self.hidesBottomBarWhenPushed = YES;
    _hasBelongedToViewController = NO;
    _photoCount = NSNotFound;
    _previousLayoutBounds = CGRectZero;
    _currentPageIndex = 0;
    _previousPageIndex = NSUIntegerMax;
    _zoomPhotosToFill = YES;
    _performingLayout = NO; // Reset on view did appear
    _rotating = NO;
    _viewIsActive = NO;
    _photos = [[NSMutableArray alloc] init];
    _thumbPhotos = [[NSMutableArray alloc] init];
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _currentGridContentOffset = CGPointMake(0, CGFLOAT_MAX);
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    if ([self respondsToSelector:@selector(transitioningDelegate)])
    {
        self.transitioningDelegate = self;
    }
}

- (void)dealloc {
    _pagingScrollView.delegate = nil;
    [self releaseAllUnderlyingPhotos:NO];
    [[SDImageCache sharedImageCache] clearMemory]; // clear memory
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent {
    // Create a copy in case this array is modified while we are looping through
    // Release photos
    NSArray *copy = [_photos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            if (preserveCurrent && p == [self photoAtIndex:self.currentIndex]) {
                continue; // skip current
            }
            [p unloadUnderlyingImage];
        }
    }
    // Release thumbs
    copy = [_thumbPhotos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            [p unloadUnderlyingImage];
        }
    }
}

- (void)didReceiveMemoryWarning {
    
    // Release any cached data, images, etc that aren't in use.
    [self releaseAllUnderlyingPhotos:YES];
    //	[_recycledPages removeAllObjects];
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}

#pragma mark - View Loading

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    // View
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;

    // Setup paging scrolling view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.delegate = self;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    [self.view addSubview:_pagingScrollView];
    
    [self reloadData];
    
    // Super
    [super viewDidLoad];
    
}

- (void)performLayout {
    
    // Setup pages
    @synchronized(self)
    {
        [_visiblePages removeAllObjects];
    }
    [_recycledPages removeAllObjects];
    
    // Content offset
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;

}

// Release any retained subviews of the main view.
- (void)viewDidUnload {
    _currentPageIndex = 0;
    _pagingScrollView = nil;
    _visiblePages = nil;
    _recycledPages = nil;
    _progressHUD = nil;
    [super viewDidUnload];
}

- (BOOL)presentingViewControllerPrefersStatusBarHidden {
    UIViewController *presenting = self.presentingViewController;
    if (presenting) {
        if ([presenting isKindOfClass:[UINavigationController class]]) {
            presenting = [(UINavigationController *)presenting topViewController];
        }
    } else {
        // We're in a navigation controller so get previous one!
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            presenting = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        }
    }
    if (presenting) {
        return [presenting prefersStatusBarHidden];
    } else {
        return NO;
    }
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
    
    // Super
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    /*
    BOOL fullScreen = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if (SYSTEM_VERSION_LESS_THAN(@"7")) fullScreen = self.wantsFullScreenLayout;
#endif
    if (fullScreen && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        if (SYSTEM_VERSION_LESS_THAN(@"7")) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
#pragma clang diagnostic push
        } else {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
        }
    }*/
}

- (void)viewWillDisappear:(BOOL)animated {
    
    /*
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self &&
        ![self.navigationController.viewControllers containsObject:self]) {
        
        // State
        _viewIsActive = NO;
        
        
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    // Status bar
    BOOL fullScreen = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if (SYSTEM_VERSION_LESS_THAN(@"7")) fullScreen = self.wantsFullScreenLayout;
#endif
    if (fullScreen && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    }*/
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    // Super
    [super viewWillDisappear:animated];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent && _hasBelongedToViewController) {
        [NSException raise:@"MWPhotoBrowser Instance Reuse" format:@"MWPhotoBrowser instances cannot be reused."];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (!parent) _hasBelongedToViewController = YES;
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutVisiblePages];
}

- (void)layoutVisiblePages {
    // Flag
    _performingLayout = YES;
    
    // Remember index
    NSUInteger indexPriorToLayout = _currentPageIndex;
    
   	// Get paging scroll view frame to determine if anything needs changing
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    // Frame needs changing
//    if (!_skipNextPagingScrollViewPositioning) {
//        _pagingScrollView.frame = pagingScrollViewFrame;
//    }
//    _skipNextPagingScrollViewPositioning = NO;;
    
    // Recalculate contentSize based on current orientation
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];

    
    // Adjust frames and configuration of each visible page
    @synchronized(_visiblePages) {
        for (BJZoomingScrollView *page in _visiblePages) {
            NSUInteger index = page.index;
            page.frame = [self frameForPageAtIndex:index];
            if (page.captionView) {
                page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
            }
            // Adjust scales if bounds has changed since last time
            if (!CGRectEqualToRect(_previousLayoutBounds, self.view.bounds)) {
                // Update zooms for new bounds
                [page adjustMaxMinZoomScalesForCurrentBounds];
                _previousLayoutBounds = self.view.bounds;
            }
        }
    }
    
    // Adjust contentOffset to preserve page location based on values collected prior to location
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
    [self didStartViewingPageAtIndex:_currentPageIndex]; // initial
    
    // Reset
    _currentPageIndex = indexPriorToLayout;
    _performingLayout = NO;

}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    // Remember page index before rotation
    _pageIndexBeforeRotation = _currentPageIndex;
    _rotating = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Perform layout
    _currentPageIndex = _pageIndexBeforeRotation;
    
    // Layout
    [self layoutVisiblePages];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _rotating = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    _pageIndexBeforeRotation = _currentPageIndex;
    _rotating = YES;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        _currentPageIndex = _pageIndexBeforeRotation;
        [self layoutVisiblePages];

    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _rotating = NO;
    }];
}

#pragma mark - Data

- (NSUInteger)currentIndex {
    return _currentPageIndex;
}

- (void)reloadData {
    
    // Reset
    _photoCount = NSNotFound;
    
    // Get data
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [self releaseAllUnderlyingPhotos:YES];
    [_photos removeAllObjects];
    [_thumbPhotos removeAllObjects];
    for (int i = 0; i < numberOfPhotos; i++) {
        [_photos addObject:[NSNull null]];
        [_thumbPhotos addObject:[NSNull null]];
    }
    
    // Update current page index
    if (numberOfPhotos > 0) {
        _currentPageIndex = MAX(0, MIN(_currentPageIndex, numberOfPhotos - 1));
    } else {
        _currentPageIndex = 0;
    }
    // Update layout
    if ([self isViewLoaded]) {
        while (_pagingScrollView.subviews.count) {
            [[_pagingScrollView.subviews lastObject] removeFromSuperview];
        }
        [self performLayout];
        [self.view setNeedsLayout];
    }
}

- (NSUInteger)numberOfPhotos {
    if (_photoCount == NSNotFound) {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}

- (id<BJPicture>)photoAtIndex:(NSUInteger)index {
    id <BJPicture> photo = nil;
    if (index < _photos.count) {
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            }
            if (photo) [_photos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}

- (id<BJPicture>)thumbPhotoAtIndex:(NSUInteger)index {
    id <BJPicture> photo = nil;
    if (index < _thumbPhotos.count) {
        if ([_thumbPhotos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:thumbPhotoAtIndex:)]) {
                photo = [_delegate photoBrowser:self thumbPhotoAtIndex:index];
            }
            if (photo) [_thumbPhotos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_thumbPhotos objectAtIndex:index];
        }
    }
    return photo;
}

- (BJCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    BJCaptionView *captionView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate photoBrowser:self captionViewForPhotoAtIndex:index];
    } else {
        id <BJPicture> photo = [self photoAtIndex:index];
        if ([photo respondsToSelector:@selector(caption)]) {
            if ([photo caption]) captionView = [[BJCaptionView alloc] initWithPhoto:photo];
        }
    }
    return captionView;
}

- (void)loadAdjacentPhotosIfNecessary:(id<BJPicture>)photo {
    BJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = page.index;
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                id <BJPicture> photo = [self photoAtIndex:pageIndex-1];
                if (![photo underlyingImage]) {
                    weakifyobject(photo);
                    [photo loadUnderlyingImageProgress:^(CGFloat process) {
                        strongifobject(photo);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            BJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
                            [page setProgress:process];
                        });
                    } completed:^(UIImage *image, NSError *error, BOOL finished) {
                        strongifobject(photo);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            BJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
                            if (page) {
                                if ([photo underlyingImage]) {
                                    // Successful load
                                    [page displayImage];
                                    [self loadAdjacentPhotosIfNecessary:photo];
                                } else {
                                    // Failed to load
                                    [page displayImageFailure];
                                }
                            }
                        });
                    }];
                    MWLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id <BJPicture> photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    weakifyobject(photo);
                    [photo loadUnderlyingImageProgress:^(CGFloat process) {
                        strongifobject(photo);
                        BJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
                        [page setProgress:process];
                        
                    } completed:^(UIImage *image, NSError *error, BOOL finished) {
                        strongifobject(photo);
                        BJZoomingScrollView *page = [self pageDisplayingPhoto:photo];
                        if (page) {
                            if ([photo underlyingImage]) {
                                // Successful load
                                [page displayImage];
                                [self loadAdjacentPhotosIfNecessary:photo];
                            } else {
                                // Failed to load
                                [page displayImageFailure];
                            }
                        }
                    }];
                    MWLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex+1);
                }
            }
        }
    }
}

#pragma mark - Paging
- (void)tilePages {
    
    // Calculate which pages should be visible
    // Ignore padding as paging bounces encroach on that
    // and lead to false page loads
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger iFirstIndex = (NSInteger)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
    NSInteger iLastIndex  = (NSInteger)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
    
    // Recycle no longer needed pages
    NSInteger pageIndex;
    @synchronized(_visiblePages)
    {
        for (BJZoomingScrollView *page in _visiblePages) {
            pageIndex = page.index;
            if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
                [_recycledPages addObject:page];
                [page.captionView removeFromSuperview];
                [page.selectedButton removeFromSuperview];
                [page prepareForReuse];
                [page removeFromSuperview];
                MWLog(@"Removed page at index %lu", (unsigned long)pageIndex);
            }
        }
        [_visiblePages minusSet:_recycledPages];
    }
     while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
    
    // Add missing pages
    for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
            BJZoomingScrollView *page = [self dequeueRecycledPage];
            if (!page) {
//                page = [[BJZoomingScrollView alloc] initWithPhotoBrowser:self];
                page = [[BJZoomingScrollView alloc] init];
                page.photoBrowser = self;
            }
            @synchronized(_visiblePages)
            {
                [_visiblePages addObject:page];
            }
            [self configurePage:page forIndex:index];
            
            [_pagingScrollView addSubview:page];
            MWLog(@"Added page at index %lu", (unsigned long)index);
            
            // Add caption
            BJCaptionView *captionView = [self captionViewForPhotoAtIndex:index];
            if (captionView) {
                captionView.frame = [self frameForCaptionView:captionView atIndex:index];
                [_pagingScrollView addSubview:captionView];
                page.captionView = captionView;
            }
        }
    }
    
}

- (void)updateVisiblePageStates {
    //    NSSet *copy = [_visiblePages copy];
    //    for (BJZoomingScrollView *page in copy) {
    //
    //        // Update selection
    //        page.selectedButton.selected = [self photoIsSelectedAtIndex:page.index];
    //
    //    }
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    @synchronized(_visiblePages)
    {
        for (BJZoomingScrollView *page in _visiblePages)
            if (page.index == index) return YES;
        return NO;
    }
}

- (BJZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {

    BJZoomingScrollView *thePage = nil;
    //加锁防止多线程同时访问
    @synchronized(_visiblePages)
    {
        for (BJZoomingScrollView *page in _visiblePages) {
            if (page.index == index) {
                thePage = page; break;
            }
        }
    }
    return thePage;

}

- (BJZoomingScrollView *)pageDisplayingThumbPhoto:(id<BJPicture>)thumbPhoto {
    
    BJZoomingScrollView *thePage = nil;
    @synchronized(_visiblePages)
    {
        for (BJZoomingScrollView *page in _visiblePages) {
            if (page.photo == thumbPhoto) {
                thePage = page; break;
            }
        }
    }
    return thePage;
}
- (BJZoomingScrollView *)pageDisplayingPhoto:(id<BJPicture>)photo {
    BJZoomingScrollView *thePage = nil;
    @synchronized(_visiblePages)
    {
        for (BJZoomingScrollView *page in _visiblePages) {
            if (page.photo == photo) {
                thePage = page; break;
            }
        }
    }
    return thePage;
}

- (void)configurePage:(BJZoomingScrollView *)page forIndex:(NSUInteger)index {
    page.frame = [self frameForPageAtIndex:index];
    page.photoBrowser = self;
    page.index = index;
    
    id<BJPicture> picture = [self photoAtIndex:index];
    //原图已经存在，直接展示原图
    if (![picture imageExist]) {
        page.thumbPhoto = [self thumbPhotoAtIndex:index];
    }
    id<BJPicture> photo = [self photoAtIndex:index];
    page.photo = photo;
    WS(weakSelf);
    [page setImageDidLoadBlock:^(BJZoomingScrollView *page, id<BJPicture> picture) {
        if (picture == photo) {
            [weakSelf loadAdjacentPhotosIfNecessary:photo];
        }
    }];
    
}
- (BJZoomingScrollView *)dequeueRecycledPage {
    BJZoomingScrollView *page = [_recycledPages anyObject];
    if (page) {
        [_recycledPages removeObject:page];
    }
    return page;
}
// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    if (![self numberOfPhotos]) {
        // Show controls
        return;
    }
    
    // Release images further away than +/-1
    NSUInteger i;
    if (index > 0) {
        // Release anything < index - 1
        for (i = 0; i < index-1; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                MWLog(@"Released underlying image at index %lu", (unsigned long)i);
            }
        }
    }
    if (index < [self numberOfPhotos] - 1) {
        // Release anything > index + 1
        for (i = index + 2; i < _photos.count; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                MWLog(@"Released underlying image at index %lu", (unsigned long)i);
            }
        }
    }
    
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    id <BJPicture> currentPhoto = [self photoAtIndex:index];
    if ([currentPhoto underlyingImage]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    
    // Notify delegate
    if (index != _previousPageIndex) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:didDisplayPhotoAtIndex:)])
            [_delegate photoBrowser:self didDisplayPhotoAtIndex:index];
        _previousPageIndex = index;
    }
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}
- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return CGRectIntegral(pageFrame);
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = index * pageWidth;
    return CGPointMake(newOffset, 0);}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) height = 32;
    return CGRectIntegral(CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height));
}

- (CGRect)frameForCaptionView:(BJCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x,
                                     pageFrame.size.height - captionSize.height,
                                     pageFrame.size.width,
                                     captionSize.height);
    return CGRectIntegral(captionFrame);
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // Checks
    if (!_viewIsActive || _performingLayout || _rotating) return;
    
    [self tilePages];
    
    // Calculate current page
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
    if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
    NSUInteger previousCurrentPage = _currentPageIndex;
    _currentPageIndex = index;
    if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }
}

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
    // Change page
    if (index < [self numberOfPhotos]) {
        CGRect pageFrame = [self frameForPageAtIndex:index];
        [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - PADDING, 0) animated:animated];
    }
}
#pragma mark - Control Hiding / Showing

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - Properties
- (void)setCurrentPhotoIndex:(NSUInteger)index {
    // Validate
    NSUInteger photoCount = [self numberOfPhotos];
    if (photoCount == 0) {
        index = 0;
    } else {
        if (index >= photoCount)
            index = [self numberOfPhotos]-1;
    }
    _currentPageIndex = index;
    if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index animated:NO];
        if (!_viewIsActive)
            [self tilePages]; // Force tiling if view is not visible
    }

}

#pragma mark - Actions

- (void)actionButtonPressed:(id)sender {
    if (_actionsSheet) {
        
        // Dismiss
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
        
    } else {
        
        // Only react when image has loaded
        id <BJPicture> photo = [self photoAtIndex:_currentPageIndex];
        if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
            
            // If they have defined a delegate method then just message them
            if ([self.delegate respondsToSelector:@selector(photoBrowser:actionButtonPressedForPhotoAtIndex:)]) {
                
                // Let delegate handle things
                [self.delegate photoBrowser:self actionButtonPressedForPhotoAtIndex:_currentPageIndex];
                
            } else {
                
                // Handle default actions
                if (SYSTEM_VERSION_LESS_THAN(@"6")) {
                    
                    // Old handling of activities with action sheet
                    if ([MFMailComposeViewController canSendMail]) {
                        _actionsSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                                           otherButtonTitles:NSLocalizedString(@"Save", nil), NSLocalizedString(@"Copy", nil), NSLocalizedString(@"Email", nil), nil];
                    } else {
                        _actionsSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                                           otherButtonTitles:NSLocalizedString(@"Save", nil), NSLocalizedString(@"Copy", nil), nil];
                    }
                    _actionsSheet.tag = ACTION_SHEET_OLD_ACTIONS;
                    _actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        [_actionsSheet showFromBarButtonItem:sender animated:YES];
                    } else {
                        [_actionsSheet showInView:self.view];
                    }
                    
                } else {
                    
                    // Show activity view controller
                    NSMutableArray *items = [NSMutableArray arrayWithObject:[photo underlyingImage]];
                    if (photo.caption) {
                        [items addObject:photo.caption];
                    }
                    self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
                    
                    // Show loading spinner after a couple of seconds
                    double delayInSeconds = 2.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        if (self.activityViewController) {
                            [self showProgressHUDWithMessage:nil];
                        }
                    });
                    
                    // Show
                    typeof(self) __weak weakSelf = self;
                    [self.activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
                        weakSelf.activityViewController = nil;
                        [weakSelf hideProgressHUD:YES];
                    }];
                    // iOS 8 - Set the Anchor Point for the popover
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 8000
                    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
                        self.activityViewController.popoverPresentationController.barButtonItem = _actionButton;
                    }
#endif
                    [self presentViewController:self.activityViewController animated:YES completion:nil];
                    
                }
                
            }
        }
    }
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == ACTION_SHEET_OLD_ACTIONS) {
        // Old Actions
        _actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                [self savePhoto]; return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
                [self copyPhoto]; return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
                [self emailPhoto]; return;
            }
        }
    }
}

#pragma mark - Action Progress

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark - Actions

- (void)savePhoto {
    id <BJPicture> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"保存中", @"Displayed with ellipsis as 'Saving...' when an item is in the process of being saved")]];
        [self performSelector:@selector(actuallySavePhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallySavePhoto:(id<BJPicture>)photo {
    if ([photo underlyingImage]) {
        UIImageWriteToSavedPhotosAlbum([photo underlyingImage], self,
                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self showProgressHUDCompleteMessage: error ? NSLocalizedString(@"保存失败", @"Informing the user a process has failed") : NSLocalizedString(@"保存成功", @"Informing the user an item has been saved")];
}

- (void)copyPhoto {
    id <BJPicture> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"复制中", @"Displayed with ellipsis as 'Copying...' when an item is in the process of being copied")]];
        [self performSelector:@selector(actuallyCopyPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyCopyPhoto:(id<BJPicture>)photo {
    if ([photo underlyingImage]) {
        [[UIPasteboard generalPasteboard] setData:UIImagePNGRepresentation([photo underlyingImage])
                                forPasteboardType:@"public.png"];
        [self showProgressHUDCompleteMessage:NSLocalizedString(@"复制成功", @"Informing the user an item has finished copying")];
    }
}

- (void)emailPhoto {
    id <BJPicture> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"加载", @"Displayed with ellipsis as 'Preparing...' when an item is in the process of being prepared")]];
        [self performSelector:@selector(actuallyEmailPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyEmailPhoto:(id<BJPicture>)photo {
    if ([photo underlyingImage]) {
        MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
        emailer.mailComposeDelegate = self;
        [emailer setSubject:NSLocalizedString(@"照片", nil)];
        [emailer addAttachmentData:UIImagePNGRepresentation([photo underlyingImage]) mimeType:@"png" fileName:@"Photo.png"];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            emailer.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        [self presentViewController:emailer animated:YES completion:nil];
        [self hideProgressHUD:NO];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"邮件", nil)
                                                        message:NSLocalizedString(@"邮件发送失败，请重试", nil)
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"取消", nil) otherButtonTitles:nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self.animator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.animator;
}

- (void)presentInViewController:(UIViewController *)viewController
                     completion:(void (^)(void))completion {
    id<BJPicture> picture = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
        picture = [_delegate photoBrowser:self photoAtIndex:_currentPageIndex];
    }
    
    id<BJPicture> thumbPicture = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:thumbPhotoAtIndex:)]) {
        thumbPicture = [_delegate photoBrowser:self thumbPhotoAtIndex:_currentPageIndex];
    }
    
    UIView *fromView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:thumbImageViewAtIndex:)]) {
        fromView = [_delegate photoBrowser:self thumbImageViewAtIndex:_currentPageIndex];
    }

    
//    id<BJPicture> picture = [self photoAtIndex:_currentPageIndex];
    //如果本地已经存在原图, 先加在到缓存
    if (fromView && [picture imageExist]) {
        self.animator = [[BJPictureZoomAnimator alloc] init];
        self.animator.delegate = self;
        self.originOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [picture loadUnderlyingImageOnlyLocal:YES progress:nil completed:^(UIImage *image, NSError *error, BOOL finished) {
            self.animator.fromImage = image;
            [self view];
            BJZoomingScrollView *cell = [self pageDisplayedAtIndex:_currentPageIndex];
            [cell displayImage];
            [viewController presentViewController:self animated:YES completion:completion];
        }];
    } else if (fromView && [thumbPicture imageExist]) {
        self.animator = [[BJPictureZoomAnimator alloc] init];
        self.animator.delegate = self;
        self.originOrientation = [UIApplication sharedApplication].statusBarOrientation;
        
        [thumbPicture loadUnderlyingImageOnlyLocal:YES progress:nil completed:^(UIImage *image, NSError *error, BOOL finished) {
            [self view];
            BJZoomingScrollView *cell = [self pageDisplayedAtIndex:_currentPageIndex];
            [cell displayThumbImage];
            
            self.animator.fromImage = image;
            [viewController presentViewController:self animated:YES completion:completion];
        }];
    } else {
        self.animator = nil;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [viewController presentViewController:self animated:YES completion:completion];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (flag) {
        self.originOrientation = [UIApplication sharedApplication].statusBarOrientation;

        BJZoomingScrollView *cell = [self pageDisplayedAtIndex:_currentPageIndex];
        
        UIView *toView = nil;
        if ([_delegate respondsToSelector:@selector(photoBrowserWillFinishModalPresentation:)])
        {
            [_delegate photoBrowserWillFinishModalPresentation:self];
        }
        if ([_delegate respondsToSelector:@selector(photoBrowser:thumbImageViewAtIndex:)]) {
            toView = [_delegate photoBrowser:self thumbImageViewAtIndex:_currentPageIndex];
        }
        
        id<BJPicture> picture =  nil;
        if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
            picture = [_delegate photoBrowser:self photoAtIndex:_currentPageIndex];
        }
        
        UIView *fromView = [cell photoImageView];
        
        if ([picture imageExist] && fromView && !fromView.isHidden) {
            self.animator = [[BJPictureZoomAnimator alloc] init];
            self.animator.delegate = self;
        } else {
            self.animator = nil;
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        }
        
        [super dismissViewControllerAnimated:YES completion:completion];
        
    } else {
        self.animator = nil;
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}

#pragma mark - BJPictureZoomAnimatorDelegate

- (UIView *)fromViewForAnimator:(BJPictureZoomAnimator *)animator {
    if ([self isBeingPresented]) {
        UIView *view = nil;
        if ([_delegate respondsToSelector:@selector(photoBrowser:thumbImageViewAtIndex:)]) {
            view = [_delegate photoBrowser:self thumbImageViewAtIndex:_currentPageIndex];
        }
        return view;
    } else if ([self isBeingDismissed]) {
        BJZoomingScrollView *cell = [self pageDisplayedAtIndex:_currentPageIndex];
        return [cell photoImageView];
    }
    
    return nil;
}

- (UIInterfaceOrientation)fromOrientationForAnimator:(BJPictureZoomAnimator *)animator {
    if ([self isBeingPresented]) {
        return self.originOrientation;
    } else if ([self isBeingDismissed]) {
        return self.originOrientation;
    }
    return UIInterfaceOrientationPortrait;
}

- (UIView *)toViewForAnimator:(BJPictureZoomAnimator *)animator {
    if ([self isBeingPresented]) {
        [self layoutVisiblePages];
        BJZoomingScrollView *cell = [self pageDisplayedAtIndex:_currentPageIndex];
        [cell adjustMaxMinZoomScalesForCurrentBounds];
        return [cell photoImageView];
    } else if ([self isBeingDismissed]) {
        UIView *view = nil;
        if ([_delegate respondsToSelector:@selector(photoBrowser:thumbImageViewAtIndex:)]) {
            view = [_delegate photoBrowser:self thumbImageViewAtIndex:_currentPageIndex];
        }
        return view;
    }
    
    return nil;
}

- (UIInterfaceOrientation)toOrientationForAnimator:(BJPictureZoomAnimator *)animator {
    if ([self isBeingPresented]) {
        return [self interfaceOrientation];
    } else if ([self isBeingDismissed]) {
        
//        if ([_delegate respondsToSelector:@selector(photoBrowser:thumbImageViewAtIndex:)]) {
//            UIView *view = [_delegate photoBrowser:self thumbImageViewAtIndex:_currentPageIndex];
//            return [[view viewController] interfaceOrientation];
//        }
        return [self interfaceOrientation];
    }
    return UIInterfaceOrientationPortrait;
}

@end
