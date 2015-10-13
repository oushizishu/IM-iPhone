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

@class GetGroupMemberModel;

@interface NetWorkTool : NSObject

+ (BJNetRequestOperation *)hermesSyncConfig:(onSuccess)succ
                                    failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesSendMessage:(IMMessage *)message
                                        succ:(onSuccess)succ
                                     failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetContactSucc:(onSuccess)succ
                                       failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesPostPollingRequestUserLastMsgId:(int64_t)last_user_msg_id
                                               excludeUserMsgIds:(NSString *)excludeUserMsgIds
                                              group_last_msg_ids:(NSString *)group_last_msg_ids
                                                    currentGroup:(int64_t)groupId
                                                            succ:(onSuccess)succ
                                                         failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetMsg:(int64_t)eid
                                groupId:(int64_t)groupId
                                    uid:(int64_t)uid
                               userRole:(IMUserRole)userRole
                          excludeMsgIds:(NSString *)excludeMsgIds
                                   succ:(onSuccess)succ
                                failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesStorageUploadImage:(IMMessage *)message
                                               succ:(onSuccess)succ
                                            failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesStorageUploadAudio:(IMMessage *)message
                                               succ:(onSuccess)succ
                                            failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesChangeRemarkNameUserId:(int64_t)userId
                                               userRole:(IMUserRole)userRole
                                             remarkName:(NSString *)remarkName
                                                   succ:(onSuccess)succ
                                                failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetUserInfo:(int64_t)userId
                                        role:(IMUserRole)userRole
                                        succ:(onSuccess)succ
                                     failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetGroupProfile:(int64_t)groupId
                                            succ:(onSuccess)succ
                                         failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesAddRecentContactId:(int64_t)userId
                                               role:(IMUserRole)userRole
                                               succ:(onSuccess)succ
                                            failure:(onFailure)failure;

#pragma mark - Group
+ (BJNetRequestOperation *)hermesSetGroupMsgWithGroupId:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status
                                                   succ:(onSuccess)succ
                                                failure:(onFailure)failure;
+ (BJNetRequestOperation *)hermesChangeGroupNameWithGroupId:(int64_t)groupId newName:(NSString *)name
                                                       succ:(onSuccess)succ
                                                    failure:(onFailure)failure;
+ (BJNetRequestOperation *)hermesGetGroupMemberWithModel:(GetGroupMemberModel *)model
                                                    succ:(onSuccess)succ
                                                 failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index
                                                      succ:(onSuccess)succ
                                                   failure:(onFailure)failure;
+ (BJNetRequestOperation *)hermesDisbandGroupWithGroupId:(int64_t)groupId
                                                    succ:(onSuccess)succ
                                                 failure:(onFailure)failure;
+ (BJNetRequestOperation *)hermesLeaveGroupWithGroupId:(int64_t)groupId
                                                  succ:(onSuccess)succ
                                               failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesSetGroupPushStatusWithGroupId:(int64_t)groupId pushStatus:(IMGroupPushStatus)status
                                                          succ:(onSuccess)succ
                                                       failure:(onFailure)failure;
@end
