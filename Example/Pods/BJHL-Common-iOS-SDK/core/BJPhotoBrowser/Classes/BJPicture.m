//
//  MWPhoto.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "BJPicture.h"
#import "BJPictueBrowser.h"
#import "SDWebImageDecoder.h"
#import "SDWebImageManager.h"
#import "SDWebImageOperation.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface BJPicture () {
    id <SDWebImageOperation> _webImageOperation;
}

- (void)imageLoadingComplete:(BJImageLoadCompletedBlock)completedBlock error:(NSError *)error finished:(BOOL)finished;

@end

@implementation BJPicture

@synthesize underlyingImage = _underlyingImage; // synth property from protocol

#pragma mark - Class Methods

- (void)dealloc {
    
}

+ (BJPicture *)photoWithImage:(UIImage *)image {
	return [[BJPicture alloc] initWithImage:image];
}

+ (BJPicture *)photoWithURL:(NSURL *)url {
	return [[BJPicture alloc] initWithURL:url];
}

#pragma mark - Init

- (id)initWithImage:(UIImage *)image {
	if ((self = [super init])) {
		_image = image;
	}
	return self;
}

- (id)initWithURL:(NSURL *)url {
	if ((self = [super init])) {
		_photoURL = [url copy];
	}
	return self;
}

#pragma mark - MWPhoto Protocol Methods

- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageProgress:(BJImageLoadProgressBlock)progressBlock
                           completed:(BJImageLoadCompletedBlock)completedBlock {
    [self loadUnderlyingImageOnlyLocal:NO progress:progressBlock completed:completedBlock];
}

- (void)loadUnderlyingImageOnlyLocal:(BOOL)flag
                            progress:(BJImageLoadProgressBlock)progressBlock
                           completed:(BJImageLoadCompletedBlock)completedBlock {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    @try {
        if (self.underlyingImage) {
            [self imageLoadingComplete:completedBlock error:nil finished:YES];
        } else {
            [self performLoadUnderlyingImageOnlyLocal:flag progress:progressBlock completed:completedBlock];
        }
    }
    @catch (NSException *exception) {
        self.underlyingImage = nil;
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedFailureReasonErrorKey:exception.reason}];
        [self imageLoadingComplete:completedBlock error:error finished:NO];

    }
    @finally {
    }
}

// Set the underlyingImage
- (void)performLoadUnderlyingImageOnlyLocal:(BOOL)flag progress:(BJImageLoadProgressBlock)progressBlock
                                 completed:(BJImageLoadCompletedBlock)completedBlock {
    
    // Get underlying image
    if (_image) {
        
        // We have UIImage!
        self.underlyingImage = _image;
        [self imageLoadingComplete:completedBlock error:nil finished:YES];
        
    } else if (_photoURL) {
        
        // Check what type of url it is
        if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            
            // Load from asset library async
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    @try {
                        ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                        [assetslibrary assetForURL:_photoURL
                                       resultBlock:^(ALAsset *asset){
                                           ALAssetRepresentation *rep = [asset defaultRepresentation];
                                           CGImageRef iref = [rep fullScreenImage];
                                           if (iref) {
                                               self.underlyingImage = [UIImage imageWithCGImage:iref];
                                           }
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [self imageLoadingComplete:completedBlock error:nil finished:YES];
                                           });
                                       }
                                      failureBlock:^(NSError *error) {
                                          self.underlyingImage = nil;
                                          MWLog(@"Photo from asset library error: %@",error);
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self imageLoadingComplete:completedBlock error:error finished:NO];
                                          });
                                      }];
                    } @catch (NSException *e) {
                        MWLog(@"Photo from asset library error: %@", e);
                        
                        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedFailureReasonErrorKey:e.reason}];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self imageLoadingComplete:completedBlock error:error finished:NO];
                        });                    }
                }
            });
            
        } else if ([_photoURL isFileReferenceURL]) {
            
            // Load from local file async
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    @try {
                        self.underlyingImage = [UIImage imageWithContentsOfFile:_photoURL.path];
                        if (!_underlyingImage) {
                            MWLog(@"Error loading photo from path: %@", _photoURL.path);
                        }
                    } @finally {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self imageLoadingComplete:completedBlock error:nil finished:YES];
                        });
                    }
                }
            });
            
        } else {
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            
            if (flag) {
                [[SDImageCache sharedImageCache] queryDiskCacheForKey:[manager cacheKeyForURL:_photoURL] done:^(UIImage *image, SDImageCacheType cacheType) {
                    if (cacheType == SDImageCacheTypeNone) {
                        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
                        [self imageLoadingComplete:completedBlock error:error finished:NO];
                        
                    } else {
                        self.underlyingImage = image;
                        [self imageLoadingComplete:completedBlock error:nil finished:YES];
                    }
                }];
            } else {
                // Load async from web (using SDWebImage)
                @try {
                    _webImageOperation = [manager downloadImageWithURL:_photoURL
                                                               options:0
                                                              progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                                  if (expectedSize > 0) {
                                                                      float progress = receivedSize / (float)expectedSize;
                                                                      if (progressBlock) {
                                                                          progressBlock(progress);
                                                                      }
                                                                  }
                                                              }
                                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                                 if (error) {
                                                                     MWLog(@"SDWebImage failed to download image: %@", error);
                                                                 }
                                                                 _webImageOperation = nil;
                                                                 self.underlyingImage = image;
                                                                 [self imageLoadingComplete:completedBlock error:error finished:finished];
                                                                 
                                                             }];
                } @catch (NSException *e) {
                    MWLog(@"Photo from web: %@", e);
                    _webImageOperation = nil;
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedFailureReasonErrorKey:e.reason}];
                    [self imageLoadingComplete:completedBlock error:error finished:NO];
                }
            }
        }
        
    } else {
        
        // Failed - no source
        @throw [NSException exceptionWithName:nil reason:nil userInfo:nil];
        
    }
}

- (BOOL)imageExist {
    BOOL isExist = NO;
    // Get underlying image
    if (_image) {
        isExist = YES;
    } else if (_photoURL) {
        // Check what type of url it is
        if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            isExist = YES;
        } else if ([_photoURL isFileReferenceURL]) {
            isExist = YES;
        } else {
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            isExist = [[SDImageCache sharedImageCache] diskImageExistsWithKey:[manager cacheKeyForURL:_photoURL]];
        }
        
    } else {
        isExist = NO;
    }
    return isExist;
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
	self.underlyingImage = nil;
}

- (void)imageLoadingComplete:(BJImageLoadCompletedBlock)completedBlock error:(NSError *)error finished:(BOOL)finished {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Notify on next run loop
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completedBlock) {
            completedBlock(self.underlyingImage, error, finished);
        }
    });
}

- (void)cancelAnyLoading {
    if (_webImageOperation) {
        [_webImageOperation cancel];
    }
}

- (void)loadLocalImageAndNotify {
    
}

@end
