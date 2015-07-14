//
//  IMBaseOperation.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import <Foundation/Foundation.h>

@interface IMBaseOperation : NSOperation

- (void)doOperationOnBackground;
- (void)doAfterOperationOnMain;
@end
