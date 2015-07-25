//
//  IMMessage+ViewModel.h
//  BJHL-IM-iOS-SDK
//
//  Created by Randy on 15/7/23.
//  Copyright (c) 2015年 YangLei-bjhl. All rights reserved.
//

#import "IMMessage.h"

@interface IMMessage (ViewModel)

- (BOOL)isMySend;    //是否是自己发送的
- (BOOL)isRead;      //是否已读

- (IMMessageStatus)deliveryStatus;

- (NSURL *)headImageURL;
- (NSString *)nickName;

//text
- (NSString *)content;
@end
