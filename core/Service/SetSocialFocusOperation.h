//
//  SetSocialFocusOperation.h
//  Pods
//
//  Created by 杨磊 on 15/10/21.
//
//

#import "IMBaseOperation.h"
#import "BJIMService.h"

@interface SetSocialFocusOperation : IMBaseOperation

@property (nonatomic, weak) BJIMService *imService;
@property (nonatomic, assign) BOOL bAddFocus;
@property (nonatomic, strong) User *contact;
@property (nonatomic, strong) User *owner;

@end
