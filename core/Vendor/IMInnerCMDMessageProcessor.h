//
//  IMInnerCMDMessageProcessor.h
//  Pods
//
//  Created by 杨磊 on 15/10/22.
//
//

#import <Foundation/Foundation.h>
#import "BJIMService.h"
#import "IMMessage.h"

@interface IMInnerCMDMessageProcessor : NSObject

/**
 *  处理内部 cmd 消息
 *
 *  @param message   <#message description#>
 *  @param imService <#imService description#>
 *
 *  @return true 内部处理成功，不需要返回给外部
 */
+ (BOOL)processMessage:(IMMessage *)message withService:(BJIMService *)imService;

@end
