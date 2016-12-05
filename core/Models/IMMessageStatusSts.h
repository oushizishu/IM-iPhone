//
//  IMMessageStatusSts.h
//  Pods
//
//  Created by 杨磊 on 2016/12/5.
//
//

#import <Foundation/Foundation.h>

@class IMMessage;
@interface IMMessageStatusSts : NSObject

@property (nonatomic, weak) IMMessage *message;

- (void)markStartSend;
- (void)markStartSendServer;
- (void)markFinishSendWithResult:(BOOL)succOrFail;

- (void)printMessageStatictis;

@end
