//
//  UIViewTap.h
//  Momento
//
//  Created by Michael Waterfall on 04/11/2009.
//  Copyright 2009 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BJTapDetectingViewDelegate;

@interface BJTapDetectingView : UIView {}

@property (nonatomic, weak) id <BJTapDetectingViewDelegate> tapDelegate;

@end

@protocol BJTapDetectingViewDelegate <NSObject>

@optional

- (void)view:(UIView *)view singleTapDetected:(UIGestureRecognizer *)gest;
- (void)view:(UIView *)view doubleTapDetected:(UIGestureRecognizer *)gest;
- (void)view:(UIView *)view tripleTapDetected:(UIGestureRecognizer *)gest;
- (void)view:(UIView *)view longPressDetected:(UIGestureRecognizer *)gest;
@end