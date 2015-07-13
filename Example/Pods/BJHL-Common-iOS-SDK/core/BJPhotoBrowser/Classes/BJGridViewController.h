//
//  MWGridViewController.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 08/10/2013.
//
//

#import <UIKit/UIKit.h>
#import "BJPictueBrowser.h"

@interface BJGridViewController : UICollectionViewController {}

@property (nonatomic, assign) BJPictueBrowser *browser;
@property (nonatomic) BOOL selectionMode;
@property (nonatomic) CGPoint initialContentOffset;

@end
