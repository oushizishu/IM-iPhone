//
//  BJChatInpuMoreViewController.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/27.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatInputMoreViewController.h"
#import <PureLayout.h>
#import "BJActionCollectionViewCell.h"
#import "BJSendMessageHelper.h"

#import <MobileCoreServices/MobileCoreServices.h>


@interface BJChatInputMoreViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *editList;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@end

@implementation BJChatInputMoreViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.editList = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ChatInputMore" ofType:@"plist"]];
    [self.view addSubview:self.collectionView];
    [self.collectionView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([BJActionCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass([BJActionCollectionViewCell class])];
}


#pragma mark - Action

- (void)sendImageMessage:(UIImage *)image
{
    NSString *filePath = nil;
    @TODO("保存图片到本地，获取路径");
    [BJSendMessageHelper sendImageMessage:filePath chatInfo:self.chatInfo];
}

- (void)showCameraView
{
    if ([self.delegate respondsToSelector:@selector(chatInputDidEndEdit)]) {
        [self.delegate chatInputDidEndEdit];
    }
#if TARGET_IPHONE_SIMULATOR
    @TODO("模拟器不支持拍照");
#elif TARGET_OS_IPHONE
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    [self.navigationController presentViewController:self.imagePicker animated:YES completion:NULL];
#endif
}

- (void)showPictureView
{
    if ([self.delegate respondsToSelector:@selector(chatInputDidEndEdit)]) {
        [self.delegate chatInputDidEndEdit];
    }
    
#if TARGET_IPHONE_SIMULATOR
    @TODO("模拟器不支持拍照");
#elif TARGET_OS_IPHONE
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    [self.navigationController presentViewController:self.imagePicker animated:YES completion:NULL];
#endif
}

- (void)didSelectWithKey:(NSString *)key;
{
    if ([key isEqualToString:@"picture"]) {
        [self showPictureView];
    }
    else if ([key isEqualToString:@"camera"])
    {
        [self showCameraView];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];

    UIImage *orgImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self sendImageMessage:orgImage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionView delegate

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.editList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJActionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BJActionCollectionViewCell class]) forIndexPath:indexPath];
    if (!cell) {
        cell = [[BJActionCollectionViewCell alloc] init];
    }
    NSDictionary *editDic = [self.editList objectAtIndex:indexPath.row];
    NSString *imageName = [editDic objectForKey:@"icon"];
    cell.imageView.image = [UIImage imageNamed:imageName];
    cell.nameLabel.text = [editDic objectForKey:@"name"];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *editDic = [self.editList objectAtIndex:indexPath.row];
    [self didSelectWithKey:[editDic objectForKey:@"key"]];
}

#pragma mark - set get
- (UICollectionView *)collectionView
{
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(60, 60);
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 5;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

- (UIImagePickerController *)imagePicker
{
    if (_imagePicker == nil) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.modalPresentationStyle= UIModalPresentationOverFullScreen;
        _imagePicker.delegate = self;
    }
    
    return _imagePicker;
}

@end