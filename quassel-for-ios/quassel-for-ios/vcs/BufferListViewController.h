// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>
#import "../QuasselCoreConnection.h"

@interface BufferListViewController : UITableViewController
{
}

@property (strong, nonatomic) QuasselCoreConnection *quasselCoreConnection;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *disconnectButton;

@property (nonatomic) BOOL canReloadBufferListAndSelectLastUsedOne;

- (void) clickRowForBufferId:(BufferId*)bufferId;
- (void) reloadRowForBufferId:(BufferId*)bufferId;

- (void) goToPreviousBuffer;
- (void) goToNextBuffer;

- (void) reloadBufferListAndSelectLastUsedOne;

- (void) quasselSocketDidDisconnect;



@end
