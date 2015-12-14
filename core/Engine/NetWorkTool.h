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

+ (BJNetRequestOperation *)hermesGetGroupDetail:(int64_t)groupId
                                           succ:(onSuccess)succ
                                        failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetGroupMembers:(int64_t)groupId
                                            page:(NSInteger)page
                                        pageSize:(NSInteger)pageSize
                                            succ:(onSuccess)succ
                                         failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesTransferGroup:(int64_t)groupId
                                   transfer_id:(int64_t)transfer_id
                                 transfer_role:(int64_t)transfer_role
                                          succ:(onSuccess)succ
                                       failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesSetGroupAvatar:(int64_t)groupId
                                         avatar:(int64_t)avatar
                                           succ:(onSuccess)succ
                                        failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesSetGroupAdmin:(int64_t)groupId
                                   user_number:(int64_t)user_number
                                     user_role:(int64_t)user_role
                                        status:(int64_t)status
                                          succ:(onSuccess)succ
                                       failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesRemoveGroupMember:(int64_t)groupId
                                       user_number:(int64_t)user_number
                                         user_role:(int64_t)user_role
                                              succ:(onSuccess)succ
                                           failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetGroupFiles:(int64_t)groupId
                                  last_file_id:(int64_t)last_file_id
                                          succ:(onSuccess)succ
                                       failure:(onFailure)failure;

+ (NSOperationQueue *)getGroupFileUploadQueue;

+ (BJNetRequestOperation *)doNetworkRequest:(RequestParams *)requestParams
                                    success:(onSuccess)success
                                    failure:(onFailure)failure
                                      retry:(onRetryRequest)retry
                                   progress:(onProgress)progress;

+ (BJNetRequestOperation *)hermesUploadGroupFile:(NSString*)attachment
                                        filePath:(NSString*)filePath
                                        fileName:(NSString*)fileName
                                         success:(onSuccess)success
                                         failure:(onFailure)failure
                                        progress:(onProgress)progress;

+ (BJNetRequestOperation *)hermesAddGroupFile:(int64_t)groupId
                                   storage_id:(int64_t)storage_id
                                     fileName:(NSString*)fileName
                                         succ:(onSuccess)succ
                                      failure:(onFailure)failure;

+ (NSOperationQueue *)getGroupFileDownloadQueue;

+ (BJNetRequestOperation *)doDownloadResource:(RequestParams *)requestParams
                                 fileDownPath:(NSString *)filePath
                                      success:(onSuccess)success
                                        retry:(onRetryRequest)retry
                                      failure:(onFailure)failure
                                     progress:(onProgress)progress;

+ (BJNetRequestOperation *)hermesDownloadGroupFile:(NSString*)fileUrl
                                          filePath:(NSString*)filePath
                                           success:(onSuccess)success
                                           failure:(onFailure)failure
                                          progress:(onProgress)progress;

+ (BJNetRequestOperation *)hermesPreviewGroupFile:(int64_t)groupId
                                          file_id:(int64_t)file_id
                                             succ:(onSuccess)succ
                                          failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesDeleteGroupFile:(int64_t)groupId
                                         file_id:(int64_t)file_id
                                            succ:(onSuccess)succ
                                         failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesCreateGroupNotice:(int64_t)groupId
                                           content:(NSString*)content
                                              succ:(onSuccess)succ
                                           failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesGetGroupNotice:(int64_t)groupId
                                        last_id:(int64_t)last_id
                                      page_size:(int64_t)page_size
                                           succ:(onSuccess)succ
                                        failure:(onFailure)failure;

+ (BJNetRequestOperation *)hermesRemoveGroupNotice:(int64_t)notice_id
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
