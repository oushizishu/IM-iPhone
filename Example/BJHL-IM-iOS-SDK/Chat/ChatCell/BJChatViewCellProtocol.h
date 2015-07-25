//
//  BJChatViewCellProtocol.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/22.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol BJChatViewCellProtocol <NSObject>
@required
/**
 *  实现初始化方法，外部只调用此方法
 *
 *  @return
 */
- (instancetype)init;
-(void)setCellInfo:(id)info indexPath:(NSIndexPath *)indexPath;
+ (CGFloat)cellHeightWithInfo:(id)dic indexPath:(NSIndexPath *)indexPath;

@optional
- (id)getCellInfo;
- (NSIndexPath *)getIndexPath;
@end
