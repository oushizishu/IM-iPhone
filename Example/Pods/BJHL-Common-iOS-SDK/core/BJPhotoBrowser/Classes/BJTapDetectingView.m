//
//  UIViewTap.m
//  Momento
//
//  Created by Michael Waterfall on 04/11/2009.
//  Copyright 2009 d3i. All rights reserved.
//

#import "BJTapDetectingView.h"

@implementation BJTapDetectingView

- (id)init {
	if ((self = [super init])) {
		self.userInteractionEnabled = YES;
        [self addGesture];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		self.userInteractionEnabled = YES;
        [self addGesture];
	}
	return self;
}
- (void)addGesture
{
    UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleSingleTap:)];
    singleFingerOne.numberOfTouchesRequired = 1; //手指数
    singleFingerOne.numberOfTapsRequired = 1; //tap次数
    
    UITapGestureRecognizer *singleFingerTwo = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleDoubleTap:)];
    singleFingerTwo.numberOfTouchesRequired = 1; //手指数
    singleFingerTwo.numberOfTapsRequired = 2; //tap次数
    
    
    UITapGestureRecognizer *singleFingerThree = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(handleTripleTap:)];
    singleFingerThree.numberOfTouchesRequired = 1; //手指数
    singleFingerThree.numberOfTapsRequired = 3; //tap次数
    
    //如果不加下面的话，当单指双击时，会先调用单指单击中的处理，再调用单指双击中的处理
    [singleFingerOne requireGestureRecognizerToFail:singleFingerTwo];
    [singleFingerTwo requireGestureRecognizerToFail:singleFingerThree];
    
    UILongPressGestureRecognizer *longPressGest = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    
    [singleFingerThree requireGestureRecognizerToFail:longPressGest];
    
    [self addGestureRecognizer:singleFingerOne];
    [self addGestureRecognizer:singleFingerTwo];
    [self addGestureRecognizer:singleFingerThree];
    [self addGestureRecognizer:longPressGest];
    
    
}
- (void)handleSingleTap:(UITapGestureRecognizer *)gest {
    
    if ([_tapDelegate respondsToSelector:@selector(view:singleTapDetected:)])
        [_tapDelegate view:self singleTapDetected:gest];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gest {
    if ([_tapDelegate respondsToSelector:@selector(view:doubleTapDetected:)])
        [_tapDelegate view:self doubleTapDetected:gest];
}

- (void)handleTripleTap:(UITapGestureRecognizer *)gest {
    if ([_tapDelegate respondsToSelector:@selector(view:tripleTapDetected:)])
        [_tapDelegate view:self tripleTapDetected:gest];
}
- (void)handleLongPress:(UITapGestureRecognizer *)gest
{
    if (gest.state == UIGestureRecognizerStateBegan) {
        if (_tapDelegate && [_tapDelegate respondsToSelector:@selector(view:longPressDetected:)])
        {
            [_tapDelegate view:self longPressDetected:gest];
        }
    }
}

@end
