// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>

#import "SignedId.h"
#import "QuasselCoreConnection.h"
#import "Message.h"
#import "PullTableView.h"
#import "UserListTableViewController.h"

@interface BufferViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, PullTableViewDelegate, UIActionSheetDelegate>
{
    BufferId* bufferId;
    enum BufferType bufferType;
    
    QuasselCoreConnection *quasselCoreConnection;
    NSArray *messages;
    
    CGPoint originalOffset;
    UIView *activeField;
    
}

@property (nonatomic) CGRect viewSizeBefore;
@property (nonatomic) UITextField *inputTextField;


- (void) setCurrentBufferId:(BufferId*)bI;
- (BufferId*) currentBufferId;
- (void) addMessage:(Message*)msg  received:(enum ReceiveStyle)style onIndex:(int)i;
- (void) addMessages:(NSArray*)messages  received:(enum ReceiveStyle)style;


- (void) quasselSocketDidDisconnect;

@property (nonatomic) enum BufferType bufferType;
@property (strong, nonatomic) QuasselCoreConnection *quasselCoreConnection;
@property (strong, nonatomic) NSArray *messages;


- (void) showOrHideBufferListBarButtonItem;

@property (strong, nonatomic) UIBarButtonItem *disconnectButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *userListButton;

@property (strong, nonatomic) UIBarButtonItem *rewindButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;

@property (strong, nonatomic) UIBarButtonItem *jpqButton; // joins parts quits

@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) NSString *messageClipboardString;
@property (strong, nonatomic) NSArray *messageUrls;


@property (strong, nonatomic) UserListTableViewController* userListTableViewController;
@property (strong, nonatomic) UIPopoverController* userListTableViewControllerPopoverController;

@property (nonatomic) NSInteger tabCompleteIndex;
@property (nonatomic) NSString *storedString;
-(void) tabCompleteNick;

@end
