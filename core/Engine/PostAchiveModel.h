//
//  PostAchiveModel.h
//  Pods
//
//  Created by 杨磊 on 15/7/28.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface PostAchiveModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *resId;
@property (nonatomic, copy) NSString *url;

@end
