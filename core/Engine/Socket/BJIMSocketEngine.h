//
//  BJIMSocketEngine.h
//  Pods
//
//  Created by 杨磊 on 15/9/7.
//
//

#import <Foundation/Foundation.h>
#import "BJIMAbstractEngine.h"

@interface BJIMSocketEngine : BJIMAbstractEngine
- (void)syncConfig;

- (void)start;

- (void)stop;

- (void)postMessage:(IMMessage *)message;

- (void)postPullRequest:(int64_t)max_user_msg_id
        excludeUserMsgs:(NSString *)excludeUserMsgs
       groupsLastMsgIds:(NSString *)group_last_msg_ids
           currentGroup:(int64_t)groupId;

@end
