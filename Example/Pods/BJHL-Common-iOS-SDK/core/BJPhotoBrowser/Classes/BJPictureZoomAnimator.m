//
//  BJPictureAnimator.m
//  BJEducation_student
//
//  Created by binluo on 15/5/18.
//  Copyright (c) 2015年 Baijiahulian. All rights reserved.
//

#import "BJPictureZoomAnimator.h"
#import "UIView+Basic.h"

@implementation BJPictureZoomAnimator


- (id)init {
    if (self = [super init]) {
        self.duration = 0.35;
    }
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = [transitionContext containerView];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [self _animationFromViewController:fromViewController
                      toViewController:toViewController
                         containerView:containerView
                              duration:duration
                     transitionContext:transitionContext];
}


#pragma mark - Private

- (CGAffineTransform)transformForFromOrientation:(UIInterfaceOrientation)fromOrientation toOrientation:(UIInterfaceOrientation)toOrientation {
    
    // direction and angle
    CGFloat angle = 0.0;
    switch (toOrientation) {
        case UIInterfaceOrientationPortrait: {
            switch (fromOrientation) {
                case UIInterfaceOrientationPortraitUpsideDown:
                    angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
                    break;
                    
                case UIInterfaceOrientationLandscapeLeft:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                    
                case UIInterfaceOrientationLandscapeRight:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                    
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            switch (fromOrientation) {
                case UIInterfaceOrientationPortrait:
                    angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
                    break;
                    
                case UIInterfaceOrientationLandscapeLeft:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                    
                case UIInterfaceOrientationLandscapeRight:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                    
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
            
        case UIInterfaceOrientationLandscapeLeft: {
            switch (fromOrientation) {
                case UIInterfaceOrientationLandscapeRight:
                    angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                    
                case UIInterfaceOrientationPortrait:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                    
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
            
        case UIInterfaceOrientationLandscapeRight: {
            switch (fromOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
                    angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
                    break;
                    
                case UIInterfaceOrientationPortrait:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                    
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
    }
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
    
    return rotation;
}

- (void)_animationFromViewController:(UIViewController *)fromViewController
                    toViewController:(UIViewController *)toViewController
                       containerView:(UIView *)containerView
                            duration:(NSTimeInterval)duration
                   transitionContext:(id <UIViewControllerContextTransitioning>)transitionContext
{
    
    UIImageView *fromViewSnapshot = [[UIImageView alloc] init];
    fromViewSnapshot.clipsToBounds = YES;
    fromViewSnapshot.backgroundColor = [UIColor clearColor];
    fromViewSnapshot.contentMode = UIViewContentModeScaleAspectFill;
    
    UIView *fromView = [self.delegate fromViewForAnimator:self];
    UIView *toView = [self.delegate toViewForAnimator:self];
    UIInterfaceOrientation fromOrientation = [self.delegate fromOrientationForAnimator:self];
    UIInterfaceOrientation toOrientation = [self.delegate toOrientationForAnimator:self];

    if (self.fromImage) {
        fromViewSnapshot.image = self.fromImage;
    } else {
        fromViewSnapshot.image = [UIView captureView:fromView];
    }
    fromViewSnapshot.frame = [containerView convertRect:fromView.frame fromView:fromView.superview];
    
    fromView.hidden = YES;
    
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    toViewController.view.alpha = 0;
    toView.hidden = YES;
    
    [containerView addSubview:toViewController.view];
    [containerView addSubview:fromViewSnapshot];
    
    fromViewSnapshot.transform = [self transformForFromOrientation:fromOrientation toOrientation:toOrientation];
    
    [UIView animateWithDuration:duration animations:^{
        toViewController.view.alpha = 1.0;
        CGRect frame = CGRectZero;
        
        fromViewSnapshot.transform = CGAffineTransformIdentity;
        
        if (toView && toView.window) {
            frame = toView.frame;
            frame = [containerView convertRect:toView.frame fromView:toView.superview];
        } else {
            if (fromView) {
                frame = fromView.bounds;
            }
            CGFloat width = MIN(150, frame.size.width);
            CGFloat height = 0;
            if (frame.size.width) {
                height = frame.size.height * width/frame.size.width;
            }
            frame = CGRectMake((containerView.frame.size.width - width)/2, (containerView.frame.size.height - height)/2, width, height);
            
            fromViewSnapshot.alpha = 0;
        }
        fromViewSnapshot.frame = frame;
    } completion:^(BOOL finished) {
        toView.hidden = NO;
        fromView.hidden = NO;
        [fromViewSnapshot removeFromSuperview];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    
}

@end
