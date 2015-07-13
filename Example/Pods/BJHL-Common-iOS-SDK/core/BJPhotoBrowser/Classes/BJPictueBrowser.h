//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "BJPicture.h"
#import "BJPictureProtocol.h"
#import "BJCaptionView.h"
#import "BJPictureZoomAnimator.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

@class BJPictueBrowser;

@protocol BJPictureBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(BJPictueBrowser *)photoBrowser;
- (id <BJPicture>)photoBrowser:(BJPictueBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional

- (UIView *)photoBrowser:(BJPictueBrowser *)photoBrowser thumbImageViewAtIndex:(NSUInteger)index;

- (id <BJPicture>)photoBrowser:(BJPictueBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index;
- (BJCaptionView *)photoBrowser:(BJPictueBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
- (NSString *)photoBrowser:(BJPictueBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(BJPictueBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(BJPictueBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index;
- (BOOL)photoBrowser:(BJPictueBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index;
- (void)photoBrowser:(BJPictueBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected;
- (void)photoBrowserDidFinishModalPresentation:(BJPictueBrowser *)photoBrowser;

- (void)photoBrowserWillFinishModalPresentation:(BJPictueBrowser *)photoBrowser;


@end

@interface BJPictueBrowser : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIViewControllerTransitioningDelegate, BJPictureZoomAnimatorDelegate>

@property (nonatomic, weak) id<BJPictureBrowserDelegate> delegate;
@property (nonatomic) BOOL zoomPhotosToFill;
@property (nonatomic, readonly) NSUInteger currentIndex;

// Init
- (id)initWithDelegate:(id <BJPictureBrowserDelegate>)delegate;

// Reloads the photo browser and refetches data
- (void)reloadData;

// Set page that photo browser starts on
- (void)setCurrentPhotoIndex:(NSUInteger)index;


- (void)presentInViewController:(UIViewController *)viewController
                     completion:(void (^)(void))completion;

- (void)dismissViewControllerAnimated: (BOOL)flag completion: (void (^)(void))completion;

@end
