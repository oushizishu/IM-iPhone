//
//  AutoResponseList.h
//  Pods
//
//  Created by 杨磊 on 2016/10/28.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface AutoResponseSetting : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) NSInteger contentId;

@end

@interface AutoResponseItem : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger contentId;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *createTime;

@end

@interface AutoResponseList : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) AutoResponseSetting *setting;
@property (nonatomic, strong) NSArray<AutoResponseItem *> *list;
@end


