//
//  NetTool.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
#import <BJHL-Common-iOS-SDK/BJCommonProxy.h>
#import "IMMessage.h"
#import "IMEnvironment.h"

@interface NetWorkTool : NSObject

+ (BJNetRequestOperation *)hermesSyncConfig:(onSuccess)succ
                                    failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesSendMessage:(IMMessage *)message
                                        succ:(onSuccess)succ
                                     failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetContactSucc:(onSuccess)succ
                                       failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesPostPollingRequestUserLastMsgId:(int64_t)last_user_msg_id
                                              group_last_msg_ids:(NSString *)group_last_msg_ids
                                                    currentGroup:(int64_t)groupId
                                                            succ:(onSuccess)succ
                                                         failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetMsg:(int64_t)eid
                                groupId:(int64_t)groupId
                                    uid:(int64_t)uid
                          excludeMsgIds:(NSString *)excludeMsgIds
                                   succ:(onSuccess)succ
                                failure:(onFailure)failure;

@end
