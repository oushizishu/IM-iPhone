/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "DXFaceView.h"

@interface DXFaceView ()<UIScrollViewDelegate>
{
    MyFacialView *_facialView;
}
@property (weak, nonatomic) UIPageControl *pageCon;
@end

@implementation DXFaceView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _facialView = [[MyFacialView alloc] initWithFrame: CGRectMake(5, 5, frame.size.width - 10, self.bounds.size.height - 10)];
        [_facialView loadFacialView:1 size:CGSizeMake(30, 30)];
        _facialView.facialDelegate = self;
        _facialView.delegate = self;
        [self addSubview:_facialView];
        
        UIPageControl *pageCon = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, 20, 10)];
        pageCon.numberOfPages = 2;
        pageCon.currentPage = 0;
        pageCon.currentPageIndicatorTintColor = BJChatColorFromRGB(0xff9900);
        pageCon.pageIndicatorTintColor = BJChatColorFromRGB(0xcccccc);
        
        CGRect fr = pageCon.frame;
        fr.origin = CGPointMake((frame.size.width-fr.size.width)/2, frame.size.height-fr.size.height-5);
        pageCon.frame = fr;
        [self addSubview:pageCon];
        _pageCon = pageCon;
    }
    return self;
}

#pragma mark - FacialViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x/scrollView.frame.size.width;
    self.pageCon.currentPage = page;
}

#pragma mark - MyFacialViewDelegate

- (void)selectThenSendImage:(UIImage *)img emoji:(NSString *)emoji{
    if (_delegate) {
        [_delegate selectThenSendImage:img emoji:emoji];
    }
}

#pragma mark - public

- (BOOL)stringIsFace:(NSString *)string
{
    if ([_facialView.faces containsObject:string]) {
        return YES;
    }
    
    return NO;
}

@end
