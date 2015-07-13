//
//  UIImageViewTap.m
//  Momento
//
//  Created by Michael Waterfall on 04/11/2009.
//  Copyright 2009 d3i. All rights reserved.
//

#import "BJTapDetectingImageView.h"

@implementation BJTapDetectingImageView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = YES;
        [self addGesture];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    if ((self = [super initWithImage:image])) {
        self.userInteractionEnabled = YES;
        [self addGesture];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    if ((self = [super initWithImage:image highlightedImage:highlightedImage])) {
        self.userInteractionEnabled = YES;
        [self addGesture];
    }
    return self;
}

//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//	UITouch *touch = [touches anyObject];
//	NSUInteger tapCount = touch.tapCount;
//	switch (tapCount) {
//		case 1:
//			//[self handleSingleTap:touch];
//			break;
//		case 2:
//			[self handleDoubleTap:touch];
//			break;
//		case 3:
//			[self handleTripleTap:touch];
//			break;
//		default:
//			break;
//	}
//	[[self nextResponder] touchesEnded:touches withEvent:event];
//}

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
    
    if ([_tapDelegate respondsToSelector:@selector(imageView:singleTapDetected:)])
        [_tapDelegate imageView:self singleTapDetected:gest];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gest {
    if ([_tapDelegate respondsToSelector:@selector(imageView:doubleTapDetected:)])
        [_tapDelegate imageView:self doubleTapDetected:gest];
}

- (void)handleTripleTap:(UITapGestureRecognizer *)gest {
    if ([_tapDelegate respondsToSelector:@selector(imageView:tripleTapDetected:)])
        [_tapDelegate imageView:self tripleTapDetected:gest];
}
- (void)handleLongPress:(UITapGestureRecognizer *)gest
{
    if (gest.state == UIGestureRecognizerStateBegan) {
        if (_tapDelegate && [_tapDelegate respondsToSelector:@selector(imageView:longPressDetected:)])
        {
            [_tapDelegate imageView:self longPressDetected:gest];
        }
    }
}
@end
