//
//  BJIMEngine.h
//  BJIM
//
//  Created by 杨磊 on 15/5/8.
//  Copyright (c) 2015年 杨磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BJIMAbstractEngine.h"
#import "IMMessage.h"

@interface BJIMHttpEngine : BJIMAbstractEngine

- (void)start;

- (void)stop;

- (void)postMessage:(IMMessage *)message;

- (void)postPullRequest:(int64_t)max_user_msg_id
           excludeUserMsgs:(NSString *)excludeUserMsgs
       groupsLastMsgIds:(NSString *)group_last_msg_ids
           currentGroup:(int64_t)groupId;

- (void)syncConfig;

@end
