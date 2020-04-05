// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "QuasselCoreConnection.h"
#import "QuasselCoreConnectionDelegate.h"
#import "BufferListViewController.h"
#import "BufferViewController.h"

//#define QUASSEL_DEBUG_PROTOCOL 1

@interface AppDelegate : UIResponder <UIApplicationDelegate, QuasselCoreConnectionDelegate, UISplitViewControllerDelegate>
{
    // Multitasking crap
    UIBackgroundTaskIdentifier bgTask;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) QuasselCoreConnection *quasselCoreConnection;

- (BufferListViewController*) bufferListViewController;
- (BufferViewController*) bufferViewController;
- (void) bufferViewControllerDidAppear;

- (UIViewController*) detailViewController;

- (void) startConnectingTo:(NSString*)hostName port:(int)port userName:(NSString*)userName passWord:(NSString*)passWord;


@property (strong, nonatomic) UIPopoverController *bufferListViewControllerPopoverController;
@property (strong, nonatomic) UIBarButtonItem *bufferListBarButtonItem;

@property (strong, nonatomic) NSString *lastErrorMessage;

- (void) goToPreviousBuffer;
- (void) goToNextBuffer;

+ (AppDelegate*) instance;

@property (nonatomic) BOOL shouldAutoReconnect;
- (void) doReconnectIfNecessary;

- (BOOL)toggleJpqShown:(BufferId*)bufferId;
- (BOOL)isJpqShown:(BufferId*)bufferId;

@end
