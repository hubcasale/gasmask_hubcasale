//
//  NotificationHelper.m
//  Gas Mask
//
//  Created by Siim Raud on 16.11.12.
//  Copyright (c) 2012 Clockwise. All rights reserved.
//

#import "NotificationHelper.h"

#import <UserNotifications/UserNotifications.h>

// NSUserNotification has been deprecated since macOS 11; use the
// UserNotifications framework instead.

@interface NotificationHelper () <UNUserNotificationCenterDelegate>
@end

@implementation NotificationHelper

+ (NotificationHelper *)sharedDelegate
{
    static NotificationHelper *delegate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegate = [[NotificationHelper alloc] init];
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = delegate;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError *error) {
            if (error) {
                logDebug(@"Notification authorization failed: %@", error);
            }
        }];
    });
    return delegate;
}

+ (void)notify:(NSString*)title message:(NSString*)message
{
    [self sharedDelegate];

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title ?: @"";
    content.body = message ?: @"";

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                          content:content
                                                                          trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                           withCompletionHandler:^(NSError *error) {
        if (error) {
            logDebug(@"Failed to deliver notification: %@", error);
        }
    }];
}

// Show notifications even while Gas Mask is the active application.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList);
}

@end
