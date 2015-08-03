//
//  StoreRecentContactsOperation.h
//  Pods
//
//  Created by 杨磊 on 15/8/3.
//
//

#import "IMBaseOperation.h"

@class BJIMService;
@interface StoreRecentContactsOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong) NSArray *users;

@end
