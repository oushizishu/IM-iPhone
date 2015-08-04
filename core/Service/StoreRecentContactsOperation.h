//
//  StoreRecentContactsOperation.h
//  Pods
//
//  Created by 杨磊 on 15/8/3.
//
//

#import "IMBaseOperation.h"
#import "LoadRecentContactsOperation.h"

@class BJIMService;
@interface StoreRecentContactsOperation : LoadRecentContactsOperation

@property (nonatomic, strong) NSArray *users;

@end
