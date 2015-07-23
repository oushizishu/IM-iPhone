//
//  BJChatUnSupportCell.m
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "BJChatUnSupportCell.h"
#import "BJChatCellFactory.h"

@interface BJChatUnSupportCell ()

@end

@implementation BJChatUnSupportCell

+ (void)load
{
    [ChatCellFactoryInstance registerClass:[self class] forMessageType:unKownMessageType];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - 
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
{
    return [[BJChatUnSupportCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([BJChatUnSupportCell class])];
}

-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
{
    [super setCellInfo:info indexPath:indexPath];
    self.textLabel.text = @"当前版本暂不支持查看此消息，请升级新版本。";
}

+ (CGFloat)cellHeightWithInfo:(id)dic indexPath:(NSIndexPath *)indexPath;
{
    return 44;
}

- (id)getCellInfo;
{
    return self.message;
}

- (NSIndexPath *)getIndexPath;
{
    return self.indexPath;
}
@end
