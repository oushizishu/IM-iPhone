//
//  IMAudioMessageBody.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMMessageBody.h"

@interface IMAudioMessageBody : IMMessageBody

@property (nonatomic, copy) NSString *file;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) NSInteger length;

@end
