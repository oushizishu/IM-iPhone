//
//  IMCardMessageBody.h
//  Pods
//
//  Created by 杨磊 on 15/7/14.
//
//

#import "IMMessageBody.h"

@interface IMCardMessageBody : IMMessageBody
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *content;
@property (copy, nonatomic) NSString *url;
@property (copy, nonatomic) NSString *thumb;
@end
