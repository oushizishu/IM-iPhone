//
//  LPJSONAdapter.h
//  Pods
//
//  Created by Randy on 16/4/8.
//
//

#import <Mantle/Mantle.h>

@interface IMJSONAdapter : MTLJSONAdapter

+ (NSValueTransformer *)NSStringJSONTransformer;

@end
