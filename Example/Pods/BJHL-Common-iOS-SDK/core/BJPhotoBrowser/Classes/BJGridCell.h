//
//  MWGridCell.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 08/10/2013.
//
//

#import <UIKit/UIKit.h>
#import "BJPicture.h"
#import "BJGridViewController.h"


@interface BJGridCell : UICollectionViewCell {}

@property (nonatomic, weak) BJGridViewController *gridController;
@property (nonatomic) NSUInteger index;
@property (nonatomic) id <BJPicture> photo;
@property (nonatomic) BOOL selectionMode;
@property (nonatomic) BOOL isSelected;

- (void)displayImage;

@end
