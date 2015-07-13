//
//  IMEnvironment.m
//  Pods
//
//  Created by 杨磊 on 15/7/13.
//
//

#import "IMEnvironment.h"
#import  <Log4Cocoa/Log4Cocoa.h>
#import <BJHL-Common-iOS-SDK/BJFileManagerTool.h>

@implementation IMEnvironment

+ (instancetype)shareInstance
{
    static IMEnvironment *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMEnvironment alloc] init];
        [instance initialize];
    });
    return instance;
}

- (void)initialize
{
    [[L4Logger rootLogger] setLevel:[L4Level all]];
    [[L4Logger rootLogger] addAppender:[[L4FileAppender alloc] initWithLayout:[L4Layout simpleLayout] fileName:@""]];
    NSString *docPath = [BJFileManagerTool docDir];
    
}
@end
