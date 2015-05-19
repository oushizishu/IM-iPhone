//
//  BJIMStorage.m
//  Pods
//
//  Created by 杨磊 on 15/5/14.
//
//

#import "BJIMStorage.h"
#import <CoreData/CoreData.h>

@interface BJIMStorage()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation BJIMStorage

- (instancetype)init
{
    self = [super init];
    if (self)
    {
//        NSManagedObjectContext
    }
    return self;
}

#pragma mark - Setter & Getter
- (NSManagedObjectContext *)managedObjectContext
{
    
}

@end
