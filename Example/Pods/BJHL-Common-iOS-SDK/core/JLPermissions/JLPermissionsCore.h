//
//  JLPermissionCore.h
//
//  Created by Joseph Laws on 11/3/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

@import Foundation;
@import UIKit;

typedef NS_ENUM(NSInteger, JLAuthorizationErrorCode) {
  JLPermissionUserDenied = 42,
  JLPermissionSystemDenied,
  JLPermissionSystemPeriousAskedDenied,//上次已经请求过一次且被拒绝了
};

typedef NS_ENUM(NSInteger, JLAuthorizationStatus) {
  JLPermissionNotDetermined = 0,
  JLPermissionDenied,
  JLPermissionAuthorized
};

typedef NS_ENUM(NSInteger, JLPermissionType) {
  JLPermissionCalendar = 0,
  JLPermissionCamera,
  JLPermissionContacts,
  JLPermissionFacebook,
  JLPermissionHealth,
  JLPermissionLocation,
  JLPermissionMicrophone,
  JLPermissionNotification,
  JLPermissionPhotos,
  JLPermissionReminders,
  JLPermissionTwitter,
};

typedef void (^AuthorizationHandler)(bool granted, NSError *error);//errorcode参考JLAuthorizationErrorCode
typedef void (^NotificationAuthorizationHandler)(NSString *deviceID, NSError *error);

@interface JLPermissionsCore : NSObject<UIAlertViewDelegate>

/**
 * @return whether or not user has granted access to the calendar
 */
- (JLAuthorizationStatus)authorizationStatus;

/**
 * Displays a dialog telling the user how to re-enable the permission in
 * the Settings application
 */
- (void)displayReenableAlert;

/**
 * The type of permission.
 */
- (JLPermissionType)permissionType;

/**
 * Opens the application system settings dialog if running on iOS 8.
 */
- (void)displayAppSystemSettings;

@end
