//
//  BJIMConversationDBManager.h
//  Pods
//
//  Created by 彭碧 on 15/7/16.
//
//

#import "BJIMDBManager.h"
#import "Conversation.h"
@interface BJIMConversationDBManager : BJIMDBManager

- (BOOL)insertConversation:(Conversation*)conversation;
@end
