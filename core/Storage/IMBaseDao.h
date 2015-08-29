//
//  IMBaseDao.h
//  Pods
//
//  Created by 杨磊 on 15/8/29.
//
//

#import <Foundation/Foundation.h>
#import "IdentityScope.h"
#import "LKDBHelper.h"


@class BJIMStorage;
@interface IMBaseDao : NSObject
@property (nonatomic, strong, readonly) IdentityScope *identityScope;
@property (nonatomic, weak) LKDBHelper *dbHelper;
@property (nonatomic, weak) BJIMStorage *imStroage;

- (void)attachEntityKey:(id)key entity:(id)entity lock:(BOOL)lock;
- (void)detach:(id)key;

- (void)clear;

@end
