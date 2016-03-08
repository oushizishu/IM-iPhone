//
//  MyContactsModel.h
//  Pods
//
//  Created by 杨磊 on 15/7/25.
//
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface MyContactsModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray *teacherList;
@property (nonatomic, strong) NSArray *organizationList;
@property (nonatomic, strong) NSArray *studentList;
@property (nonatomic, strong) NSArray *groupList;
@property (nonatomic, strong) NSArray *blackList;

@end
