//
//  BJAction.h
//  ActionDemo
//
//  Created by Mac_ZL on 15/6/3.
//  Copyright (c) 2015年 Mac_ZL. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 *  @author ZhaoLiang, 15-06-03 19:06:04
 *
 *  @brief  匹配顺序:secheme://event/
 *                  secheme://host/query
 *                  secheme://host/path?query
 *
 */
@interface BJAction : NSObject

typedef void (^ BJActionHandler)(id target,NSDictionary *payload);

/*!
 *  @author ZhaoLiang, 15-06-03 19:06:56
 *
 *  @brief  scheme 必选
 */
@property (nonatomic,strong) NSString *scheme;
/*!
 *  @author ZhaoLiang, 15-06-03 19:06:15
 *
 *  @brief  host 可选 选择的话,action通过query传递
 */
@property (nonatomic,strong) NSString *host;
/*!
 *  @author ZhaoLiang, 15-06-03 19:06:09
 *
 *  @brief  path 可选 path填写,host必选填写,选择的话，action通过query传递
 */
@property (nonatomic,strong) NSString *path;

/*!
 *  @author ZhaoLiang, 15-06-03 19:06:05
 *  actionKey
 *  @brief  default actionKey = action
 */
@property (nonatomic,strong) NSString *actionKey;

/*!
 *  @author ZhaoLiang, 15-06-03 19:06:05
 *  payload
 *  @brief payload 可选
 */
@property (nonatomic,strong) NSString *payload;

@property (strong, nonatomic) NSMutableDictionary *listeners;

+ (instancetype)shareInstance;
//监听event
- (void)on:(NSString*)event perform:(BJActionHandler)handler;
- (void)off:(NSString *)event;

- (BOOL)sendTotarget:(id)target handleWithUrl:(NSURL*)url;
@end
