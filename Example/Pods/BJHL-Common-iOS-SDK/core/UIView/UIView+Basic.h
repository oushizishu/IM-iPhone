//
//  UIView+Basic.h
//  MotherBaby
//
//  Created by Mac_ZL on 14-08-26.
//  Copyright (c) 2014年 Baijiahulian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(Basic)

//- (CGFloat)current_x;
//- (CGFloat)current_y;
//- (CGFloat)current_w;
//- (CGFloat)current_h;
//- (CGFloat)current_y_h;
//- (CGFloat)current_x_w;
//- (CGPoint)current_innerCenter;

@property (nonatomic) CGFloat current_x;

@property (nonatomic) CGFloat current_y;


@property (nonatomic) CGFloat current_w;


@property (nonatomic) CGFloat current_h;


@property (nonatomic) CGFloat current_y_h;


@property (nonatomic) CGFloat current_x_w;


@property (nonatomic, readonly) CGPoint current_innerCenter;

/**
 * Return the x coordinate on the screen.
 */
@property (nonatomic, readonly) CGFloat screenX;

/**
 * Return the y coordinate on the screen.
 */
@property (nonatomic, readonly) CGFloat screenY;

/**
 * Return the x coordinate on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGFloat screenViewX;

/**
 * Return the y coordinate on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGFloat screenViewY;

/**
 * Return the view frame on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGRect screenFrame;

/**
 * Shortcut for frame.origin
 */
@property (nonatomic) CGPoint origin;

/**
 * Shortcut for frame.size
 */
@property (nonatomic) CGSize size;

/**
 * Shortcut for center.x
 *
 * Sets center.x = centerX
 */
@property (nonatomic) CGFloat centerX;

/**
 * Shortcut for center.y
 *
 * Sets center.y = centerY
 */
@property (nonatomic) CGFloat centerY;



@property (nonatomic) CGPoint orientationCenter;

/**
 * Return the width in portrait or the height in landscape.
 */
@property (nonatomic, readonly) CGFloat orientationWidth;

/**
 * Return the height in portrait or the width in landscape.
 */
@property (nonatomic, readonly) CGFloat orientationHeight;

/**
 * Finds the first descendant view (including this view) that is a member of a particular class.
 */
- (UIView*)descendantOrSelfWithClass:(Class)cls;

/**
 * Finds the first ancestor view (including this view) that is a member of a particular class.
 */
- (UIView*)ancestorOrSelfWithClass:(Class)cls;

/**
 *  view subviews iscontain view of kind of cls
 */
- (BOOL)subViewsContaionWithClass:(Class)cls;

/**
 * Removes all subviews.
 */
- (void)removeAllSubviews;

/**
 * The view controller whose view contains this view.
 */
- (UIViewController*)viewController;


//截图
+(UIImage *)captureView:(UIView *)theView;

@end
