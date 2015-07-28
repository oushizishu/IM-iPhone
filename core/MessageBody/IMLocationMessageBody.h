//
//  IMLocationMessageBody.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMMessageBody.h"

@interface IMLocationMessageBody : IMMessageBody

@property (nonatomic, assign) double_t lat;
@property (nonatomic, assign) double_t lng;
@property (nonatomic, copy) NSString *address;


@end
