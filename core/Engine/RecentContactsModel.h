//
//  RecentContactsModel.h
//  Pods
//
//  Created by 杨磊 on 15/8/3.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface RecentContactsModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray *users;

@end
