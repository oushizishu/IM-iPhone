//
//  IMCmdMessageBody.h
//  Pods
//
//  Created by 杨磊 on 15/7/29.
//
//

#import "IMMessageBody.h"

@interface IMCmdMessageBody : IMMessageBody

@property (nonatomic, assign) NSInteger type;
@property (nonatomic, strong) NSDictionary *payload;

@end
