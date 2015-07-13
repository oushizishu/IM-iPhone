//
//  MWPhotoBrowser_Private.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 08/10/2013.
//
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "BJGridViewController.h"
#import "BJZoomingScrollView.h"
#import "BJPictureZoomAnimator.h"
#import "PictureBrowserCollectionViewCell.h"

// Declare private methods of browser
@interface BJPictueBrowser () {
    
	// Data
    NSUInteger _photoCount;
    NSMutableArray *_photos;
    NSMutableArray *_thumbPhotos;
	
    // Views
    UIScrollView *_pagingScrollView;
    
    // Paging & layout
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _currentPageIndex;
    NSUInteger _previousPageIndex;
	
    CGRect _previousLayoutBounds;
	NSUInteger _pageIndexBeforeRotation;
	
	// Navigation & controls
    MBProgressHUD *_progressHUD;
    UIActionSheet *_actionsSheet;
    

    UIStatusBarStyle _previousStatusBarStyle;

    // Misc
    BOOL _hasBelongedToViewController;
    BOOL _isVCBasedStatusBarAppearance;
    BOOL _statusBarShouldBeHidden;
	BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    CGPoint _currentGridContentOffset;
    
}

// Properties
@property (nonatomic) UIActivityViewController *activityViewController;

@property (nonatomic, strong) BJPictureZoomAnimator *animator;
@property (nonatomic, assign) UIInterfaceOrientation originOrientation;

// Layout
- (void)layoutVisiblePages;
- (void)performLayout;
- (BOOL)presentingViewControllerPrefersStatusBarHidden;

// Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated;
- (void)storePreviousNavBarAppearance;
- (void)restorePreviousNavBarAppearance:(BOOL)animated;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (BJZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (BJZoomingScrollView *)pageDisplayingPhoto:(id<BJPicture>)photo;
- (BJZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(BJZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGRect)frameForCaptionView:(BJCaptionView *)captionView atIndex:(NSUInteger)index;

// Data
- (NSUInteger)numberOfPhotos;
- (id<BJPicture>)photoAtIndex:(NSUInteger)index;
- (id<BJPicture>)thumbPhotoAtIndex:(NSUInteger)index;
- (BOOL)photoIsSelectedAtIndex:(NSUInteger)index;
- (void)setPhotoSelected:(BOOL)selected atIndex:(NSUInteger)index;
- (void)loadAdjacentPhotosIfNecessary:(id<BJPicture>)photo;
- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent;

// Actions
- (void)savePhoto;
- (void)copyPhoto;
- (void)emailPhoto;

@end

