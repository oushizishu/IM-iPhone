//
//  UtilsMacro.h
//  BJEducation_Institution
//
//  Created by Randy on 15/4/27.
//  Copyright (c) 2015年 com.bjhl. All rights reserved.
//

#ifndef BJChat_UtilsMacro_h
#define BJChat_UtilsMacro_h

#define BJChatColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

// 转成字符串
#define STRINGIFY(S) #S
// 需要解两次才解开的宏
#define DEFER_STRINGIFY(S) STRINGIFY(S)
#define PRAGMA_MESSAGE(MSG) _Pragma(STRINGIFY(message(MSG)))
// 为warning增加更多信息
#define FORMATTED_MESSAGE(MSG) "[TODO-" DEFER_STRINGIFY(__COUNTER__) "] " MSG " \n" DEFER_STRINGIFY(__FILE__) " line " DEFER_STRINGIFY(__LINE__)
// 使宏前面可以加@
#define KEYWORDIFY try {} @catch (...) {}
// 最终使用的宏
#define TODO(MSG) KEYWORDIFY PRAGMA_MESSAGE(FORMATTED_MESSAGE(MSG))

#endif
