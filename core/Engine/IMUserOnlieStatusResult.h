//
//  IMUserOnlieStatusResult.h
//  Pods
//
//  Created by 杨磊 on 2016/10/25.
//
//

#import "BJIMConstants.h"

@interface IMUserOnlieStatusResult : MTLModel<MTLJSONSerializing>


@property (nonatomic, assign) IMUserOnlineStatus onlineStatus;

@end
