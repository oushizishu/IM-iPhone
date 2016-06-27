//
//  NetTool.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"

#import "IMMessage.h"
#import "IMEnvironment.h"

#import <BJHL-Network-iOS/BJHL-Network-iOS.h>

@class GetGroupMemberModel;

@interface NetWorkTool : NSObject

+ (BJCNNetRequestOperation *)hermesSyncConfig:(BJCNOnSuccess)succ
                                    failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesSendMessage:(IMMessage *)message
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetContactSucc:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesPostPollingRequestUserLastMsgId:(int64_t)last_user_msg_id
                                               excludeUserMsgIds:(NSString *)excludeUserMsgIds
                                              group_last_msg_ids:(NSString *)group_last_msg_ids
                                                    currentGroup:(int64_t)groupId
                                                            succ:(BJCNOnSuccess)succ
                                                         failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetMsg:(int64_t)eid
                                groupId:(int64_t)groupId
                                    uid:(int64_t)uid
                               userRole:(IMUserRole)userRole
                          excludeMsgIds:(NSString *)excludeMsgIds
                                   succ:(BJCNOnSuccess)succ
                                failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesStorageUploadImage:(IMMessage *)message
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesStorageUploadAudio:(IMMessage *)message
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesChangeRemarkNameUserId:(int64_t)userId
                                               userRole:(IMUserRole)userRole
                                             remarkName:(NSString *)remarkName
                                                   succ:(BJCNOnSuccess)succ
                                                failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetUserInfo:(int64_t)userId
                                        role:(IMUserRole)userRole
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetGroupProfile:(int64_t)groupId
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetGroupDetail:(int64_t)groupId
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetGroupMembers:(int64_t)groupId
                                           page:(NSInteger)page
                                       pageSize:(NSInteger)pageSize
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesTransferGroup:(int64_t)groupId
                                   transfer_id:(int64_t)transfer_id
                                 transfer_role:(int64_t)transfer_role
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesSetGroupAvatar:(int64_t)groupId
                                         avatar:(int64_t)avatar
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesSetGroupNameAvatar:(int64_t)groupId
                                          groupName:(NSString*)groupName
                                             avatar:(int64_t)avatar
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesSetGroupAdmin:(int64_t)groupId
                                   user_number:(int64_t)user_number
                                     user_role:(int64_t)user_role
                                        status:(int64_t)status
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesRemoveGroupMember:(int64_t)groupId
                                       user_number:(int64_t)user_number
                                         user_role:(int64_t)user_role
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetGroupFiles:(int64_t)groupId
                            last_file_id:(int64_t)last_file_id
                                    succ:(BJCNOnSuccess)succ
                                 failure:(BJCNOnFailure)failure;

+ (NSOperationQueue *)getGroupFileUploadQueue;

+ (BJCNNetRequestOperation *)doNetworkRequest:(BJCNRequestParams *)requestParams
                                    success:(BJCNOnSuccess)success
                                    failure:(BJCNOnFailure)failure
                                      retry:(BJCNOnRetryRequest)retry
                                   progress:(BJCNOnProgress)progress;

+ (BJCNNetRequestOperation *)hermesUploadGroupFile:(NSString*)attachment
                              filePath:(NSString*)filePath
                              fileName:(NSString*)fileName
                               success:(BJCNOnSuccess)success
                               failure:(BJCNOnFailure)failure
                              progress:(BJCNOnProgress)progress;

+ (BJCNNetRequestOperation *)hermesUploadFaceImage:(NSString *)fileName
                                        filePath:(NSString *)filePath
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesAddGroupFile:(int64_t)groupId
                                   storage_id:(int64_t)storage_id
                                     fileName:(NSString*)fileName
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure;

+ (NSOperationQueue *)getGroupFileDownloadQueue;

+ (BJCNNetRequestOperation *)doDownloadResource:(BJCNRequestParams *)requestParams
                       fileDownPath:(NSString *)filePath
                            success:(BJCNOnSuccess)success
                              retry:(BJCNOnRetryRequest)retry
                            failure:(BJCNOnFailure)failure
                           progress:(BJCNOnProgress)progress;

+ (BJCNNetRequestOperation *)hermesDownloadGroupFile:(NSString*)fileUrl
                                filePath:(NSString*)filePath
                                 success:(BJCNOnSuccess)success
                                 failure:(BJCNOnFailure)failure
                                progress:(BJCNOnProgress)progress;

+ (BJCNNetRequestOperation *)hermesPreviewGroupFile:(int64_t)groupId
                                          file_id:(int64_t)file_id
                                             succ:(BJCNOnSuccess)succ
                                          failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesDeleteGroupFile:(int64_t)groupId
                                         file_id:(int64_t)file_id
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesCreateGroupNotice:(int64_t)groupId
                                           content:(NSString*)content
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetGroupNotice:(int64_t)groupId
                                        last_id:(int64_t)last_id
                                      page_size:(int64_t)page_size
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesRemoveGroupNotice:(int64_t)notice_id
                                          group_id:(int64_t)group_id
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesAddBlacklist:(int64_t)userId
                                     userRole:(IMUserRole)userRole
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesCancelBlacklist:(int64_t)userId
                                        userRole:(IMUserRole)userRole
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesAddRecentContactId:(int64_t)userId
                                               role:(IMUserRole)userRole
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

#pragma mark - Group
+ (BJCNNetRequestOperation *)hermesSetGroupMsgWithGroupId:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status
                                                   succ:(BJCNOnSuccess)succ
                                                failure:(BJCNOnFailure)failure;
+ (BJCNNetRequestOperation *)hermesChangeGroupNameWithGroupId:(int64_t)groupId newName:(NSString *)name
                                                       succ:(BJCNOnSuccess)succ
                                                    failure:(BJCNOnFailure)failure;
+ (BJCNNetRequestOperation *)hermesGetGroupMemberWithModel:(GetGroupMemberModel *)model
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesGetGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index
                                                      succ:(BJCNOnSuccess)succ
                                                   failure:(BJCNOnFailure)failure;
+ (BJCNNetRequestOperation *)hermesDisbandGroupWithGroupId:(int64_t)groupId
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure;
+ (BJCNNetRequestOperation *)hermesLeaveGroupWithGroupId:(int64_t)groupId
                                                  succ:(BJCNOnSuccess)succ
                                               failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesSetGroupPushStatusWithGroupId:(int64_t)groupId pushStatus:(IMGroupPushStatus)status
                                                          succ:(BJCNOnSuccess)succ
                                                       failure:(BJCNOnFailure)failure;

+ (BJCNNetRequestOperation *)hermesSetUserName:(NSString *)userName userAvatar:(NSString *)userAvatar;
@end
