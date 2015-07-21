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

+ (BJNetRequestOperation*)hermesGetContactSucc:(onSuccess)succ
                                       failure:(onFailure)failure;
@end
