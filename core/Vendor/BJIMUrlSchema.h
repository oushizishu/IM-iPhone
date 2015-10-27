//
//  BJIMUrlSchema.h
//  Pods
//
//  Created by 杨磊 on 15/10/26.
//
//

#import <Foundation/Foundation.h>

@interface BJIMUrlSchema : NSObject

+ (instancetype)shareInstance;

/**
 *  处理 hermes 内的 URL。 因为是 sdk，不会涉及到界面的跳转。
 *
 *  @param url <#url description#>
 */
- (void)handleUrl:(NSString *)url;

@end
