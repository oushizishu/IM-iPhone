/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "NSDateFormatter+Category.h"

@implementation NSDateFormatter (Category)

+ (id)dateFormatter
{
    static NSDateFormatter *dateFormate= nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        dateFormate = [[NSDateFormatter alloc] init];
    });
    return dateFormate;
}

+ (id)dateFormatterWithFormat:(NSString *)dateFormat
{
    NSDateFormatter *dateFormatter = [self dateFormatter];
    dateFormatter.dateFormat = dateFormat;
    return dateFormatter;
}

+ (id)defaultDayDateFormatter
{
    NSDateFormatter *dayDateFormatter = [self dateFormatter];
    dayDateFormatter.dateFormat = @"yyyy.MM.dd";
    return dayDateFormatter;
}

+ (id)defaultDayDateFormatter2
{
    NSDateFormatter *dayDateFormatter = [self dateFormatter];
    dayDateFormatter.dateFormat = @"yyyy-MM-dd";
    return dayDateFormatter;
}

+ (id)defaultDateFormatter
{
    NSDateFormatter *dateFormatter = [self dateFormatter];
   dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return dateFormatter;
}

+ (id)defaultDateFormatter2
{
    NSDateFormatter *dateFormatter = [self dateFormatter];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    return dateFormatter;
}

+ (id)defaultOnlyHourDateFormatter//dd
{
    NSDateFormatter *dateFormatter = [self dateFormatter];
    dateFormatter.dateFormat = @"dd";
    return dateFormatter;
}

@end
