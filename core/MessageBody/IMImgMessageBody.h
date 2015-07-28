//
//  IMImgMessageBody.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMMessageBody.h"

@interface IMImgMessageBody : IMMessageBody

@property (nonatomic, copy) NSString *file;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;

@end
