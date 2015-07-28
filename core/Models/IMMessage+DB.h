//
//  IMMessage+DB.h
//  Pods
//
//  Created by 杨磊 on 15/7/24.
//
//

#import <Foundation/Foundation.h>
#import "IMMessage.h"

@class BJIMService;
@interface IMMessage(DB)

@property (nonatomic, weak) BJIMService *imService;

- (User *)getSenderUser;
- (User *)getReceiverUser;
- (Group *)getReceiverGroup;

- (void)markRead;
- (void)markPlayed;

@end
