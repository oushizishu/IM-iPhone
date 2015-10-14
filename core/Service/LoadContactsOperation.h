//
//  LoadContactsOperation.h
//  Pods
//
//  Created by 杨磊 on 15/10/14.
//
//

#import "IMBaseOperation.h"
@class User;
@class BJIMService;

@interface LoadContactsOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, strong) User *owner;

@end
