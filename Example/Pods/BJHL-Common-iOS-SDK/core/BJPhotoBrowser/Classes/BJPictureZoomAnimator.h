//
//  BJPictureAnimator.h
//  BJEducation_student
//
//  Created by binluo on 15/5/18.
//  Copyright (c) 2015年 Baijiahulian. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BJPictureZoomAnimator;

@protocol BJPictureZoomAnimatorDelegate <NSObject>

- (UIView *)fromViewForAnimator:(BJPictureZoomAnimator *)animator;
- (UIInterfaceOrientation)fromOrientationForAnimator:(BJPictureZoomAnimator *)animator;

- (UIView *)toViewForAnimator:(BJPictureZoomAnimator *)animator;
- (UIInterfaceOrientation)toOrientationForAnimator:(BJPictureZoomAnimator *)animator;

@end

@interface BJPictureZoomAnimator : NSObject <UIViewControllerAnimatedTransitioning>

/**
 The direction of the animation.
 */
@property (nonatomic, assign) BOOL reverse;

/**
 The animation duration.
 */
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, strong) UIImage *fromImage;

@property (nonatomic, weak) id<BJPictureZoomAnimatorDelegate> delegate;

@end
