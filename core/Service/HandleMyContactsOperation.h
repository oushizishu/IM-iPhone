//
//  HandleMyContactsOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/25.
//
//

#import "IMBaseOperation.h"


@class BJIMService;
@class MyContactsModel;
@interface HandleMyContactsOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong) MyContactsModel *model;

@end
