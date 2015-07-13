//
//  JLPermissionCore.m
//
//  Created by Joseph Laws on 11/3/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLPermissionsCore.h"
#import "JLPermissionsCore+Internal.h"
@implementation JLPermissionsCore

- (NSString *)defaultTitle:(NSString *)authorizationType {
  return [NSString
      stringWithFormat:@"\"%@\" 想要访问您的 %@", [self appName], authorizationType];
}

- (NSString *)defaultMessage {
  return nil;
}

- (NSString *)defaultCancelTitle {
  return @"不允许";
}

- (NSString *)defaultGrantTitle {
  return @"确定";
}

- (NSString *)appName {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

- (UIImage *)snapshot {
  id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];

  UIGraphicsBeginImageContextWithOptions(appDelegate.window.bounds.size, NO,
                                         appDelegate.window.screen.scale);

  [appDelegate.window drawViewHierarchyInRect:appDelegate.window.bounds afterScreenUpdates:NO];

  UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return snapshotImage;
}

- (void)displayReenableAlert {
  NSString *message = [NSString stringWithFormat:@"请到 设置 -> 隐私 -> "
                                                 @"%@ 重新启用 %@'s 访问.",
                                                 [self permissionName], [self appName]];
    
    if ([self canDisplaySystemSettings]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"跳转",nil];
        alert.delegate = self;
        alert.tag = 1000;
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
    }
}

- (NSString *)permissionName {
  switch ([self permissionType]) {
    case JLPermissionCalendar:
      return @"日历";
    case JLPermissionCamera:
      return @"相机";
    case JLPermissionContacts:
      return @"通讯录";
    case JLPermissionFacebook:
      return @"Facebook";
    case JLPermissionHealth:
      return @"健康";
    case JLPermissionLocation:
      return @"位置";
    case JLPermissionMicrophone:
      return @"麦克风";
    case JLPermissionNotification:
      return @"通知";
    case JLPermissionPhotos:
      return @"照片";
    case JLPermissionReminders:
      return @"提醒";
    case JLPermissionTwitter:
      return @"Twitter";
  }
}

- (NSError *)userDeniedError {
  return [NSError errorWithDomain:@"UserDenied" code:JLPermissionUserDenied userInfo:nil];
}

- (NSError *)previouslyDeniedError {
  return [NSError errorWithDomain:@"SystemDenied" code:JLPermissionSystemPeriousAskedDenied userInfo:nil];
}

- (NSError *)systemDeniedError:(NSError *)error {
  return [NSError errorWithDomain:@"SystemDenied"
                             code:JLPermissionSystemDenied
                         userInfo:[error userInfo]];
}

- (BOOL)canDisplaySystemSettings
{
    if (IS_IOS_8 && &UIApplicationOpenSettingsURLString != NULL) {
        return YES;
    }
    return NO;
}

- (void)displayAppSystemSettings {
  if ([self canDisplaySystemSettings]) {
    NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:appSettings];
  }
}

#pragma mark - Abstract methods

- (JLPermissionType)permissionType {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass",
                                                   NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (JLAuthorizationStatus)authorizationStatus {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass",
                                                   NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (void)actuallyAuthorize {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass",
                                                   NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (void)canceledAuthorization:(NSError *)error {
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass",
                                                   NSStringFromSelector(_cmd)]
               userInfo:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  BOOL canceled = (buttonIndex == alertView.cancelButtonIndex);
  dispatch_async(dispatch_get_main_queue(), ^{
      if (alertView.tag == 1000) {
          if (!canceled) {
              [self displayAppSystemSettings];
          }
      }
      else
      {
          if (canceled) {
              [self canceledAuthorization:[self userDeniedError]];
          } else {
              [self actuallyAuthorize];
          }
      }
  });
}

@end
