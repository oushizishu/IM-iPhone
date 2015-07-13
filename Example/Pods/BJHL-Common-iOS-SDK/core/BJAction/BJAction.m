//
//  BJAction.m
//  ActionDemo
//
//  Created by Mac_ZL on 15/6/3.
//  Copyright (c) 2015年 Mac_ZL. All rights reserved.
//

#import "BJAction.h"
#import "NSURL+QueryDictionary.h"
@implementation BJAction

+ (instancetype)shareInstance
{
    static BJAction *shareBJAction= nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        shareBJAction = [[self alloc] init];
    });
    return shareBJAction;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _listeners = [[NSMutableDictionary alloc] init];
        _actionKey = @"action";
        _payload = nil;
        _host = nil;
        _path = nil;
    }
    return self;
}
- (void)on:(NSString*)type perform:(BJActionHandler)handler
{
    NSMutableArray *listenerList = [self.listeners objectForKey:type];
    
    if (listenerList == nil) {
        listenerList = [[NSMutableArray alloc] init];
        
        [self.listeners setValue:listenerList forKey:type];
    }
    [listenerList addObject:handler];
}
- (void)off:(NSString *)type
{
    [self.listeners removeObjectForKey:type];
}
- (BOOL)sendTotarget:(id)target handleWithUrl:(NSURL*)url;
{
    if ( [[url scheme] isEqualToString:self.scheme] )
    {
        if (!self.host)
        {
            //host为空的话 host作为事件传递
            NSString *eventType = [url host];
            NSString *query = [url query];
            NSDictionary *param;
            if (query) {
                NSString *decodeString = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                param = [decodeString uq_URLQueryDictionary];
            }
            
            [self triggerEventToTarget:target withEvent:eventType withData:param];
        }
        else if ([[url host] isEqualToString:self.host]) //host 存在匹配host
        {
            if (!self.path || ([[[url path] substringFromIndex:1] isEqualToString:self.path]))
            {
                //path不存在 ||  //path存在 并且相等
                NSString *query = [url query];
                NSString *decodeString = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                NSDictionary *param = [decodeString uq_URLQueryDictionary];
                [self triggerEventToTarget:target withData:param];
            }
            else
            {
                NSLog(@"匹配失败");
            }
        }
        else
        {
            NSLog(@"匹配失败");
        }
    }
    else
    {
        return NO;
    }
    return YES;
}
- (void)triggerEventToTarget:(id)target withEvent:(NSString *)event withData:(NSDictionary *) envelope
{
    NSDictionary *listeners = [self listeners];
    NSArray *listenerList = (NSArray*)[listeners objectForKey:event];
    NSDictionary *payload = envelope;
    if (envelope) {
        if (self.payload) {
            payload  = [envelope objectForKey:self.payload];
        }
    }
    for (BJActionHandler handler in listenerList) {
        handler(target, payload);
    }
}
- (void)triggerEventToTarget:(id)target withData:(NSDictionary *) envelope
{
    NSDictionary *listeners = [self listeners];
    NSString *key;
    NSDictionary *payload = envelope;
    NSArray *listenerList;
    if (envelope)
    {
        key = [envelope objectForKey:self.actionKey];
        if (self.payload) {
            payload = [envelope objectForKey:self.payload];
        }
        listenerList = (NSArray*)[listeners objectForKey:key];
        for (BJActionHandler handler in listenerList) {
            handler(target, payload);
        }
    }
}
@end
