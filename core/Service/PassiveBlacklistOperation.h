//
//  PassiveBlacklistOperation.h
//  Pods
//  说明:被动拉黑处理
//  Created by bjhl on 15/10/22.
//
//

#import "IMBaseOperation.h"
#import "BJIMService.h"

@interface PassiveBlacklistOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong)IMMessage *message;
@property (nonatomic, strong)NSMutableArray *remindMessageArray;
@end
