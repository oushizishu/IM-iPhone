//
//  BJIMConversationDBManager.m
//  Pods
//
//  Created by 彭碧 on 15/7/16.
//
//

#import "BJIMConversationDBManager.h"
#import "LKDBHelper.h"
@implementation BJIMConversationDBManager


- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (BOOL)insertConversation:(Conversation *)conversation{
    return [self.dbHelper insertToDB:conversation];
}

@end
