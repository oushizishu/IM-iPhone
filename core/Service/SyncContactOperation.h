//
//  SyncContactOperation.h
//  Pods
//
//  Created by 彭碧 on 15/7/21.
//
//

#import "IMBaseOperation.h"
@class BJIMService;
@class MyContactsModel;
@interface SyncContactOperation : IMBaseOperation
@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic,strong) MyContactsModel *model;
@end
