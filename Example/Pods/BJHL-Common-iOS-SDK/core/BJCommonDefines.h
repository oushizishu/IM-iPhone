//
//  BJCommonDefines.h
//  Pods
//
//  Created by 杨磊 on 15/6/1.
//
//

#ifndef __BJCommonDefines_h
#define __BJCommonDefines_h

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define SYSTEM_VERSION_EQUAL_OR_MORE_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

// 两种 weakself 写法
#define __WeakSelf__  __weak typeof (self)

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;


#define __WeakObject(object) __weak typeof (object)

#define weakifyself __WeakSelf__ wSelf = self;
#define strongifyself __WeakSelf__ self = wSelf;

#define weakifyobject(obj) __WeakObject(obj) $##obj = obj;
#define strongifobject(obj) __WeakObject(obj) obj = $##obj;



#endif
