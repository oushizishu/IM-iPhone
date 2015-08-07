//
//  BJIMListData.h
//  Pods
//
//  Created by Randy on 15/8/7.
//
//

#import <Foundation/Foundation.h>
#import "BJIMConstants.h"
@interface BJIMListData : MTLModel<MTLJSONSerializing>

@property (copy, nonatomic) NSArray *list;
@property (assign, nonatomic) BOOL hasMore;
@property (assign, nonatomic) NSUInteger page;

+ (NSString *)modelClassStr;

@end
