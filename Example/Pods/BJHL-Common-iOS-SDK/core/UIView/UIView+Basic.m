//
//  UIView+Basic.m
//  Picnote
//
//  Created by Mac_ZL on 14-8-26.
//  Copyright (c) 2014年 Baijiahulian. All rights reserved.
//

#import "UIView+Basic.h"
#import "UIView+Extension.h"

@implementation UIView(Basic)

- (CGFloat)current_x
{
    return self.frame.origin.x;
}

- (void)setCurrent_x:(CGFloat)current_x {
    CGRect frame = self.frame;
    frame.origin.x = current_x;
    self.frame = frame;
}


- (CGFloat)current_y
{
    return self.frame.origin.y;
}

- (void)setCurrent_y:(CGFloat)current_y {
    CGRect frame = self.frame;
    frame.origin.y = current_y;
    self.frame = frame;
}

- (CGFloat)current_w
{
    return self.frame.size.width;
}

- (void)setCurrent_w:(CGFloat)current_w {
    CGRect frame = self.frame;
    frame.size.width = current_w;
    self.frame = frame;
}

- (CGFloat)current_h
{
    return self.frame.size.height;
}

- (void)setCurrent_h:(CGFloat)current_h {
    CGRect frame = self.frame;
    frame.size.height = current_h;
    self.frame = frame;

}

- (CGFloat)current_y_h
{
    return self.frame.size.height + self.frame.origin.y;
}

- (void)setCurrent_y_h:(CGFloat)current_y_h {
    CGRect frame = self.frame;
    frame.origin.y = current_y_h - frame.size.height;
    self.frame = frame;

}

- (CGFloat)current_x_w
{
    return self.frame.size.width + self.frame.origin.x;
}

- (void)setCurrent_x_w:(CGFloat)current_x_w {
    CGRect frame = self.frame;
    frame.origin.x = current_x_w - frame.size.width;
    self.frame = frame;
}

- (CGPoint)current_innerCenter
{
    return CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
}



///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += [view current_x];
    }
    return x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += [view current_y];
    }
    return y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += [view current_x];
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            x -= scrollView.contentOffset.x;
        }
    }
    
    return x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += [view current_y];
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            y -= scrollView.contentOffset.y;
        }
    }
    return y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)screenFrame {
    return CGRectMake([self screenViewX], [self screenViewY], [self width], [self height]);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)origin {
    return self.frame.origin;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)size {
    return self.frame.size;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}



///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)centerX {
    return self.center.x;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)centerY {
    return self.center.y;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}


- (CGPoint)orientationCenter {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? CGPointMake(self.center.y, self.center.x) : self.center;
}

- (void)setOrientationCenter:(CGPoint)orientationCenter {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        self.center = CGPointMake(orientationCenter.y, orientationCenter.x);
    } else {
        self.center = orientationCenter;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)orientationWidth {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.height : self.width;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)orientationHeight {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.width : self.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)descendantOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls])
        return self;
    
    for (UIView* child in self.subviews) {
        UIView* it = [child descendantOrSelfWithClass:cls];
        if (it)
            return it;
    }
    
    return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)ancestorOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls]) {
        return self;
    } else if (self.superview) {
        return [self.superview ancestorOrSelfWithClass:cls];
    } else {
        return nil;
    }
}

- (BOOL)subViewsContaionWithClass:(Class)cls
{
    BOOL contain = NO;
    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:cls]) {
            contain = YES;
            break;
        }
    }
    return contain;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeAllSubviews {
    while (self.subviews.count) {
        UIView* child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)offsetFromView:(UIView*)otherView {
    CGFloat x = 0, y = 0;
    for (UIView* view = self; view && view != otherView; view = view.superview) {
        x += [view current_x];
        y += [view current_y];
    }
    return CGPointMake(x, y);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*)viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

#pragma mark -
+(UIImage*)captureView:(UIView *)theView
{
    CGRect rect = theView.bounds;
    //支持retina高分的关键
    if(UIGraphicsBeginImageContextWithOptions != NULL)
    {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    } else {
        UIGraphicsBeginImageContext(rect.size);
    }
    CGContextRef context =UIGraphicsGetCurrentContext();
    [theView.layer renderInContext:context];
    UIImage *img =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
@end
