//
//  BJIMStorage.m
//  Pods
//
//  Created by 杨磊 on 15/5/14.
//
//

#import "BJIMStorage.h"
#import <LKDBHelper/LKDBHelper.h>

#define IM_STRAGE_NAME @"bjhl-hermes-db"

@interface BJIMStorage()
@property (nonatomic, strong) LKDBHelper *dbHelper;

@end

@implementation BJIMStorage

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.dbHelper = [[LKDBHelper alloc] initWithDBName:IM_STRAGE_NAME];
        self.conversitionManager.dbHelper = self.dbHelper;
    }
    return self;
}



@end
