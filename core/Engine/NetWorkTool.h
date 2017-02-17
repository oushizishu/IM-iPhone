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
#import "AutoResponseList.h"

#import <BJHL-Network-iOS/BJHL-Network-iOS.h>

@class GetGroupMemberModel;

@interface NetWorkTool : NSObject

+ (void)hermesSyncConfig:(BJCNOnSuccess)succ
                                    failure:(BJCNOnFailure)failure;

+ (void)hermesSendMessage:(IMMessage *)message
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure;

+ (void)hermesGetContactSucc:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;

+ (void)hermesPostPollingRequestUserLastMsgId:(int64_t)last_user_msg_id
                                               excludeUserMsgIds:(NSString *)excludeUserMsgIds
                                              group_last_msg_ids:(NSString *)group_last_msg_ids
                                                    currentGroup:(int64_t)groupId
                                                            succ:(BJCNOnSuccess)succ
                                                         failure:(BJCNOnFailure)failure;

+ (void)hermesGetMsg:(int64_t)eid
                                groupId:(int64_t)groupId
                                    uid:(int64_t)uid
                               userRole:(IMUserRole)userRole
                          excludeMsgIds:(NSString *)excludeMsgIds
                                   succ:(BJCNOnSuccess)succ
                                failure:(BJCNOnFailure)failure;

+ (void)hermesStorageUploadImage:(IMMessage *)message
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

+ (void)hermesStorageUploadAudio:(IMMessage *)message
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

+ (void)hermesChangeRemarkNameUserId:(int64_t)userId
                                               userRole:(IMUserRole)userRole
                                             remarkName:(NSString *)remarkName
                                                   succ:(BJCNOnSuccess)succ
                                                failure:(BJCNOnFailure)failure;

+ (void)hermesGetUserInfo:(int64_t)userId
                                        role:(IMUserRole)userRole
                                        succ:(BJCNOnSuccess)succ
                                     failure:(BJCNOnFailure)failure;

+ (void)hermesGetGroupProfile:(int64_t)groupId
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (void)hermesGetGroupDetail:(int64_t)groupId
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (void)hermesGetGroupMembers:(int64_t)groupId
                                           page:(NSInteger)page
                                       pageSize:(NSInteger)pageSize
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure;

+ (void)hermesIsAdmin:(int64_t)groupId succ:(BJCNOnSuccess)succ failure:(BJCNOnFailure)failure;

+ (void)hermesGetSearchMemberList:(int64_t)groupId query:(NSString *)query succ:(BJCNOnSuccess)succ failure:(BJCNOnFailure)failure;

+ (void)hermesSetGroupMemberForbid:(int64_t)groupId
                       user_number:(int64_t)user_number
                         user_role:(int64_t)user_role
                            status:(int64_t)status
                              succ:(BJCNOnSuccess)succ
                           failure:(BJCNOnFailure)failure;

+ (void)hermesGetGroupMemberProfile:(int64_t)groupId
                  user_number:(int64_t)user_number
                     userRole:(IMUserRole)userRole
                         succ:(BJCNOnSuccess)succ
                      failure:(BJCNOnFailure)failure;


+ (void)hermesTransferGroup:(int64_t)groupId
                                   transfer_id:(int64_t)transfer_id
                                 transfer_role:(int64_t)transfer_role
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;

+ (void)hermesSetGroupAvatar:(int64_t)groupId
                                         avatar:(int64_t)avatar
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure;

+ (void)hermesSetGroupNameAvatar:(int64_t)groupId
                                          groupName:(NSString*)groupName
                                             avatar:(int64_t)avatar
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

+ (void)hermesSetGroupAdmin:(int64_t)groupId
                                   user_number:(int64_t)user_number
                                     user_role:(int64_t)user_role
                                        status:(int64_t)status
                                          succ:(BJCNOnSuccess)succ
                                       failure:(BJCNOnFailure)failure;

+ (void)hermesRemoveGroupMember:(int64_t)groupId
                                       user_number:(int64_t)user_number
                                         user_role:(int64_t)user_role
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure;

+ (void)hermesGetGroupFiles:(int64_t)groupId
                            last_file_id:(int64_t)last_file_id
                                    succ:(BJCNOnSuccess)succ
                                 failure:(BJCNOnFailure)failure;

//+ (NSOperationQueue *)getGroupFileUploadQueue;


+ (void)hermesUploadGroupFile:(NSString*)attachment
                              filePath:(NSString*)filePath
                              fileName:(NSString*)fileName
                               success:(BJCNOnSuccess)success
                               failure:(BJCNOnFailure)failure
                              progress:(BJCNOnProgress)progress;

+ (void)hermesUploadFaceImage:(NSString *)fileName
                                        filePath:(NSString *)filePath
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (void)hermesAddGroupFile:(int64_t)groupId
                                   storage_id:(int64_t)storage_id
                                     fileName:(NSString*)fileName
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure;

//+ (NSOperationQueue *)getGroupFileDownloadQueue;


+ (void)hermesDownloadGroupFile:(NSString*)fileUrl
                                filePath:(NSString*)filePath
                                 success:(BJCNOnSuccess)success
                                 failure:(BJCNOnFailure)failure
                                progress:(BJCNOnProgress)progress;

+ (void)hermesPreviewGroupFile:(int64_t)groupId
                                          file_id:(int64_t)file_id
                                             succ:(BJCNOnSuccess)succ
                                          failure:(BJCNOnFailure)failure;

+ (void)hermesDeleteGroupFile:(int64_t)groupId
                                         file_id:(int64_t)file_id
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (void)hermesCreateGroupNotice:(int64_t)groupId
                                           content:(NSString*)content
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure;

+ (void)hermesGetGroupNotice:(int64_t)groupId
                                        last_id:(int64_t)last_id
                                      page_size:(int64_t)page_size
                                           succ:(BJCNOnSuccess)succ
                                        failure:(BJCNOnFailure)failure;

+ (void)hermesRemoveGroupNotice:(int64_t)notice_id
                                          group_id:(int64_t)group_id
                                              succ:(BJCNOnSuccess)succ
                                           failure:(BJCNOnFailure)failure;

+ (void)hermesAddBlacklist:(int64_t)userId
                                     userRole:(IMUserRole)userRole
                                         succ:(BJCNOnSuccess)succ
                                      failure:(BJCNOnFailure)failure;

+ (void)hermesCancelBlacklist:(int64_t)userId
                                        userRole:(IMUserRole)userRole
                                            succ:(BJCNOnSuccess)succ
                                         failure:(BJCNOnFailure)failure;

+ (void)hermesAddRecentContactId:(int64_t)userId
                                               role:(IMUserRole)userRole
                                               succ:(BJCNOnSuccess)succ
                                            failure:(BJCNOnFailure)failure;

#pragma mark - Group
+ (void)hermesSetGroupMsgWithGroupId:(int64_t)groupId msgStatus:(IMGroupMsgStatus)status
                                                   succ:(BJCNOnSuccess)succ
                                                failure:(BJCNOnFailure)failure;
+ (void)hermesChangeGroupNameWithGroupId:(int64_t)groupId newName:(NSString *)name
                                                       succ:(BJCNOnSuccess)succ
                                                    failure:(BJCNOnFailure)failure;
+ (void)hermesGetGroupMemberWithModel:(GetGroupMemberModel *)model
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure;

+ (void)hermesGetGroupMemberWithGroupId:(int64_t)groupId userRole:(IMUserRole)userRole page:(NSUInteger)index
                                                      succ:(BJCNOnSuccess)succ
                                                   failure:(BJCNOnFailure)failure;
+ (void)hermesDisbandGroupWithGroupId:(int64_t)groupId
                                                    succ:(BJCNOnSuccess)succ
                                                 failure:(BJCNOnFailure)failure;
+ (void)hermesLeaveGroupWithGroupId:(int64_t)groupId
                                                  succ:(BJCNOnSuccess)succ
                                               failure:(BJCNOnFailure)failure;

+ (void)hermesSetGroupPushStatusWithGroupId:(int64_t)groupId pushStatus:(IMGroupPushStatus)status
                                                          succ:(BJCNOnSuccess)succ
                                                       failure:(BJCNOnFailure)failure;

+ (void)hermesSetUserName:(NSString *)userName userAvatar:(NSString *)userAvatar;

+ (void)hermesGetUserOnlineStatus:(int64_t)userId
                             role:(IMUserRole)userRole
                             succ:(BJCNOnSuccess)succ
                          failure:(BJCNOnFailure)failure;


#pragma mark - autoresponse
+ (void)hermesAddAutoResponseWithUserId:(int64_t)userId
                                   role:(IMUserRole)role
                                content:(NSString *)content
                                success:(void(^)(NSInteger contentId))succss
                                failure:(void(^)(NSError *error))failure;

+ (void)hermesEditAutoResponseWithUserId:(int64_t)userId
                                    role:(IMUserRole)role
                               contentId:(NSInteger)contentId
                                 content:(NSString *)content
                                 success:(void(^)(NSInteger contentId))succss
                                 failure:(void (^)(NSError *))failure;  

+ (void)hermesSetAutoResponseWithUserId:(int64_t)userId
                                   role:(IMUserRole)role
                                 enable:(BOOL)enable
                                success:(void(^)())succss
                                failure:(void(^)(NSError *error))failure;

+ (void)hermesSetAutoResponseWithUserId:(int64_t)userId
                                   role:(IMUserRole)role
                              contentId:(NSInteger)contentId
                                success:(void(^)())succss
                                failure:(void(^)(NSError *error))failure;

+ (void)hermesDelAutoResponseWithUserId:(int64_t)userId
                                   role:(IMUserRole)role
                              contentId:(NSInteger)contentId
                                success:(void(^)())succss
                                failure:(void(^)(NSError *error))failure;

+ (void)hermesGetAllAutoResponseWithUserId:(int64_t)userId
                                      role:(IMUserRole)role
                                   success:(void(^)(AutoResponseList *result))succss
                                   failure:(void(^)(NSError *error))failure;

@end
