#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>

void logthread(const char *msg, NSError *error) {
  NSThread *thread = [NSThread currentThread];
  if (error) {
    NSLog(@"\033[0;31m%s %@ %@\033[0m", msg, error, thread);
  } else {
    NSLog(@"%s %@", msg, thread);
  }
}

// a function using UNUserNotificationCenter to say hello world
void sayHello() {
  UNUserNotificationCenter *center =
      [UNUserNotificationCenter currentNotificationCenter];
  UNMutableNotificationContent *content =
      [[UNMutableNotificationContent alloc] init];
  content.title = @"Title";
  content.subtitle = @"Subtitle";
  content.body = @"Body 😊";
  content.categoryIdentifier = @"ACCEPT_ACTION";
  content.sound = [UNNotificationSound defaultSound];

  UNTimeIntervalNotificationTrigger *trigger =
      [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];

  UNNotificationRequest *request =
      [UNNotificationRequest requestWithIdentifier:@"Hello"
                                           content:content
                                           trigger:trigger];

  [center addNotificationRequest:request
           withCompletionHandler:^(NSError *_Nullable error) {
             logthread("addNotificationRequest", error);
           }];
}

/// Check if mainBundle.bundleIdentifier is not nil or else logs error
bool checkBundleIdentifier() {
  NSBundle *main = [NSBundle mainBundle];
  if (main.bundleIdentifier == nil) {
    NSLog(
        @"Error: mainBundle.bundleIdentifier is nil.\n"
         "  Please check Info.plist. Place the Info.plist file into the .app "
         "directory.\n"
         "  Alternatively include the Info.plist into the binary by using the "
         "`-Wl,-sectcreate,_\\__TEXT,__info_plist,Info.plist` compile flag.");
    return false;
  }
  return true;
}

@interface AppDelegate
    : NSObject <NSApplicationDelegate, UNUserNotificationCenterDelegate>
@end

@implementation AppDelegate
// NSApplicationDelegate applicationDidFinishLaunching
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  logthread("applicationDidFinishLaunching", nil);
  checkBundleIdentifier();
  UNUserNotificationCenter *center =
      [UNUserNotificationCenter currentNotificationCenter];
  center.delegate = self;
  [self requestUserNotificationAuthorization];
  sayHello();
}

- (void)requestUserNotificationAuthorization {
  UNUserNotificationCenter *center =
      [UNUserNotificationCenter currentNotificationCenter];
  [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert |
                                           UNAuthorizationOptionSound |
                                           UNAuthorizationOptionBadge)
                        completionHandler:^(BOOL granted,
                                            NSError *_Nullable error) {
                          logthread("requestAuthorizationWithOptions", error);
                          [self onUserNotificationAuthorized];
                        }];
}

- (void)onUserNotificationAuthorized {
  auto acceptAction = [UNNotificationAction
      actionWithIdentifier:@"ACCEPT_ACTION"
                     title:@"Accept"
                   options:UNNotificationActionOptionNone];
  auto actionCategory = [UNNotificationCategory
      categoryWithIdentifier:@"ACCEPT_ACTION"
                     actions:@[ acceptAction ]
           intentIdentifiers:@[]
                     options:UNNotificationCategoryOptionCustomDismissAction];
  auto center = [UNUserNotificationCenter currentNotificationCenter];
  [center setNotificationCategories:[NSSet setWithObject:actionCategory]];
}

// UNUserNotificationCenterDelegate willPresentNotification
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))
                 completionHandler
    API_AVAILABLE(macos(10.14), ios(10.0), watchos(3.0), tvos(10.0)) {
  logthread("willPresentNotification", nil);
  completionHandler(UNNotificationPresentationOptionList |
                    UNNotificationPresentationOptionBanner |
                    UNNotificationPresentationOptionSound |
                    UNNotificationPresentationOptionBadge);
}

// UNUserNotificationCenterDelegate didReceiveNotificationResponse
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)(void))completionHandler
    API_AVAILABLE(macos(10.14), ios(10.0), watchos(3.0))API_UNAVAILABLE(tvos) {
  logthread("didReceiveNotificationResponse", nil);
  completionHandler();
}
@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;
    [app run];
  }
  return 0;
}