// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "BufferViewController.h"
#import "BufferInfo.h"
#import "Message.h"
#import "QuasselUtils.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "PullTableView.h"
#import "BufferViewTableCell.h"
#import "UserListTableViewController.h"
#import "SignedId.h"

#define CELL_CONTENT_MARGIN 2.0f

@interface BufferViewController ()

@end

@implementation BufferViewController

@synthesize inputTextField;
@synthesize viewSizeBefore;

@synthesize quasselCoreConnection;
@synthesize bufferType;
@synthesize messages;

@synthesize disconnectButton;
@synthesize userListButton;

@synthesize rewindButton;
@synthesize forwardButton;

@synthesize actionSheet;
@synthesize messageClipboardString;
@synthesize messageUrls;

@synthesize userListTableViewController;
@synthesize userListTableViewControllerPopoverController;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) keyboardCallback
{
    // invalidate the current stored line.
    if (_storedString) {
        _storedString = nil;
    }
}

-(void) tabCompleteNick
{
    Boolean firstStr = false;
    NSString *complString;
    if (_storedString == nil) {
        _storedString = [inputTextField.text copy];
    }
    complString = [_storedString copy];

    // get the last word of the line
    NSRange lastIdx = [_storedString rangeOfString:@" " options:NSBackwardsSearch];

    if (lastIdx.length == 0) {
        firstStr = true;
    }

    NSString *partialNick = nil;
    if (firstStr) {
        partialNick = [_storedString copy];
    } else {
        NSRange subNick;
        subNick.location = lastIdx.location + 1;
        subNick.length = [_storedString length] - subNick.location;
        partialNick = [_storedString substringWithRange:subNick];
    }

    NSArray *nicks = [quasselCoreConnection ircUsersForChannelWithBufferId:bufferId];
    NSInteger nickCount = [nicks count];
    for (int i = 0; i < nickCount; i++) {
        NSString *nick = [[nicks objectAtIndex:(_tabCompleteIndex % nickCount)] nick];
        const char *nickStr = [nick UTF8String];
        NSLog(@"-%s\n", nickStr);
        _tabCompleteIndex++;
        if ([nick rangeOfString:partialNick options:NSCaseInsensitiveSearch].location == 0) {
            // it's good we hit the right nick
            if (firstStr) {
                inputTextField.text = [NSString stringWithFormat:@"%@: ", nick];
            } else {
                NSRange prevRange;
                prevRange.location = 0;
                prevRange.length = lastIdx.location;
                NSString *prevBeginning = [[_storedString substringWithRange:prevRange] copy];
                inputTextField.text = [NSString stringWithFormat:@"%@ %@ ", prevBeginning, nick];
            }
            break;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.tableView.separatorColor = [UIColor clearColor];
    
    disconnectButton = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect" style:UIBarButtonItemStyleBordered target:self action:@selector(disconnectPressed)];
    //userListButton = [[UIBarButtonItem alloc] initWithTitle:@"Users" style:UIBarButtonItemStyleBordered target:self action:@selector(userListPressed)];
    
    rewindButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(rewindPressed)];
    rewindButton.style = UIBarButtonItemStyleBordered;
    forwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(forwardPressed)];
    forwardButton.style = UIBarButtonItemStyleBordered;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    CGRect inputRect = CGRectMake(0, 0, self.view.frame.size.width,self.navigationController.toolbar.frame.size.height);
    inputTextField = [[UITextField alloc] initWithFrame:inputRect];
    inputTextField.text = @"WWWW";
    inputTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    CGSize size = [inputTextField.text sizeWithFont:inputTextField.font];
    inputTextField.frame = CGRectMake(0, 0, inputTextField.frame.size.width, size.height*1.5);
    //inputTextField.frame = CGRectMake(0, 0, inputTextField.frame.size.width, size.height);
    inputTextField.text = @"";
    inputTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth; 
    inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    inputTextField.placeholder = @"Type your message...";
    inputTextField.delegate = self;
    inputTextField.returnKeyType = UIReturnKeySend;
    //inputTextField.adjustsFontForContentSizeCategory = YES;

    //self.tableView.tableFooterView = inputTextField;
    UIToolbar* tabKeyToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50)];
    tabKeyToolbar.barStyle = UIBarStyleDefault;
    tabKeyToolbar.items = [NSArray arrayWithObjects:
                                   [[UIBarButtonItem alloc]initWithTitle:@"Tab" style:UIBarButtonItemStyleBordered target:self action:@selector(tabCompleteNick)],
                                   nil];
    [tabKeyToolbar sizeToFit];
    inputTextField.inputAccessoryView = tabKeyToolbar;
    [inputTextField addTarget:self action:@selector(keyboardCallback)
    forControlEvents:UIControlEventEditingChanged];
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    
    self.pullTableView.pullDelegate = self;
}

- (PullTableView*) pullTableView
{
    return (PullTableView*) self.tableView;
}

- (void) refreshTableDone
{
    self.pullTableView.pullLastRefreshDate = nil;
    self.pullTableView.pullTableIsRefreshing = NO;
}

- (void) loadMoreTableDone
{
    self.pullTableView.pullTableIsLoadingMore = NO;
}



- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    [self performSelector:@selector(refreshTableDone) withObject:nil afterDelay:3.0f];
    [self performSelector:@selector(fetchMoreBacklog) withObject:nil afterDelay:0];
}

- (void)pullTableViewDidTriggerLoadMore:(PullTableView *)pullTableView
{
    //self.pullTableView.pullTableIsLoadingMore = NO;
    [self performSelector:@selector(loadMoreTableDone) withObject:nil afterDelay:0.5];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [quasselCoreConnection sendMessage:inputTextField.text toBuffer:bufferId];
    inputTextField.text = @"";
    return NO;
}

// Also check http://stackoverflow.com/questions/2995742/how-can-i-get-a-custom-uitableview-to-automatically-scroll-to-a-selected-text-fi ?
- (void)keyboardWasShown:(NSNotification*)aNotification
{
//    inputTextField.placeholder = @"";
//    viewSizeBefore = self.view.frame;
//    
//    NSLog(@"self.view.rect = %@", NSStringFromCGRect(self.view.frame));
//     NSDictionary* info = [aNotification userInfo];
//    CGRect kbRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    kbRect = [self.view convertRect:kbRect toView:nil];
//
//    NSLog(@"keyboard rect = %@", NSStringFromCGRect(kbRect));
//
//    CGRect f = self.view.frame;
//    f.size.height = f.size.height - kbRect.size.height - self.navigationController.toolbar.frame.size.height + ;
//    self.view.frame = f;
//    NSLog(@"self.view.rect = %@", NSStringFromCGRect(self.view.frame));
    
    NSDictionary* info = [aNotification userInfo];
    CGRect bounds = [self.view bounds];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect toView:nil];

    // http://stackoverflow.com/a/29330392/2941
    CGRect convertedKeyboardFrame = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    CGRect intersection = CGRectIntersection(convertedKeyboardFrame, bounds);
    // hack!
    CGFloat theHeight = intersection.size.height;

    // iPod:
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0,
                                                       theHeight
                                                       // + inputTextField.bounds.size.height
                                                       // self.navigationController.toolbar.frame.size.height
                                                       ,0.0);
    else 
        self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0,
                                                       theHeight
                                                       //+ inputTextField.bounds.size.height
                                                       // self.navigationController.toolbar.frame.size.height
                                                       ,0.0);
    
    if (self.messages.count >= 1) {
        // First figure out how many sections there are
        NSInteger lastSectionIndex = [self.tableView numberOfSections] - 1;
        // Then grab the number of rows in the last section
        NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex] - 1;
        // Now just construct the index path
        if (lastRowIndex >= 0 && lastRowIndex >= 0) {
            NSIndexPath *pathToLastRow = [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
            [self.tableView scrollToRowAtIndexPath:pathToLastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }

}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
//    self.view.frame = viewSizeBefore;
    self.tableView.contentInset = UIEdgeInsetsZero;

}
//- (void)keyboardWasShown:(NSNotification *)aNotification {
//    CGRect keyboardBounds;
//    [[aNotification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue: &keyboardBounds];
//    int keyboardHeight = keyboardBounds.size.height;
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationBeginsFromCurrentState:YES];
//    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardBounds.size.height, 0);
//    [UIView commitAnimations];
//    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[items count] inSection:0]
//                     atScrollPosition:UITableViewScrollPositionMiddle
//                             animated:YES];
//}
//
//- (void)keyboardWasHidden:(NSNotification *)aNotification {
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationBeginsFromCurrentState:YES];
//    tableView.contentInset = UIEdgeInsetsZero;
//    [UIView commitAnimations];
//}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    } else {
        self.navigationController.toolbarHidden = YES;
    }}

- (void) viewDidDisappear:(BOOL)animated
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    } else {
        self.navigationController.toolbarHidden = YES;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    // To stop flickering animation
    //self.inputTextField.hidden = YES;
    self.tableView.tableFooterView = nil;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.navigationItem.hidesBackButton = YES;
        
        self.navigationItem.rightBarButtonItem = nil;

        self.navigationController.toolbarHidden = NO;
    } else {
    }

    self.toolbarItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],rewindButton,forwardButton,nil];

}

- (void) viewDidAppear:(BOOL)animated
{
    [self showOrHideBufferListBarButtonItem];

    [[AppDelegate instance] bufferViewControllerDidAppear];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

    } else {
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.hidesBackButton = NO;

        self.navigationController.toolbarHidden = NO;

        if (messages.count > 0) { // scroll down
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (void) setCurrentBufferId:(BufferId*)bI
{
    if ([bI isEqual:bufferId]) {
        NSLog(@"setCurrentBufferId already set, returning...");
        return;
    }
    if (!quasselCoreConnection) {
        NSLog(@"Internal Error: setCurrentBufferId has no connection set");
    }
    
    bufferId = bI;
    
    self.title = [[quasselCoreConnection.bufferIdBufferInfoMap objectForKey:bI] bufferName];
    self.bufferType = [[quasselCoreConnection.bufferIdBufferInfoMap objectForKey:bI] bufferType];
    self.messages = [quasselCoreConnection.bufferIdMessageListMap objectForKey:bI];
    
    [self.tableView reloadData];
       
    // Scroll down
    if (self.messages.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        //[self.tableView scrollRectToVisible:[self.tableView convertRect:self.tableView.tableFooterView.bounds fromView:self.tableView.tableFooterView] animated:NO];
        //CGPoint newContentOffset = CGPointMake(0, [self.tableView contentSize].height -  self.tableView.bounds.size.height);
        //[self.tableView setContentOffset:newContentOffset animated:YES];
        
        [quasselCoreConnection setLastSeenMsg:[[self.messages lastObject] messageId] forBuffer:bufferId];

        //self.inputTextField.hidden = FALSE;
    }

    if (self.bufferType == ChannelBuffer) {
        self.navigationItem.rightBarButtonItem = userListButton;
    }else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (BufferId*) currentBufferId
{
    return bufferId;
}

- (void) fetchSomeBacklog {
    [quasselCoreConnection fetchSomeBacklog:bufferId];
}

- (void) fetchMoreBacklog {
    [quasselCoreConnection fetchMoreBacklog:bufferId];
}

- (void) addMessages:(NSArray*)receivedMessages  received:(enum ReceiveStyle)style
{

    [self performSelector:@selector(refreshTableDone) withObject:nil afterDelay:0];
    
    NSLog(@"bufferViewController addMessages %lu (%d)", (unsigned long)receivedMessages.count, messages.count);
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:receivedMessages.count];
    int currentMessageCount = messages.count-receivedMessages.count;
    if (currentMessageCount <= 0)
        currentMessageCount = 0;
    if (style == ReceiveStyleAppended) {
        for (int i = 0; i < receivedMessages.count; i++)
            [indexPaths addObject:[NSIndexPath indexPathForRow:currentMessageCount+i inSection:0]];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    } else if (style == ReceiveStylePrepended) {
        for (int i = 0; i < receivedMessages.count; i++)
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView reloadData];
    }
    
    
    if (self.messages.count > 0 && style == ReceiveStyleAppended) {
        // Scroll down
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    } else if (self.messages.count > 0 && style == ReceiveStylePrepended) {
        // scroll to where we were before
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:receivedMessages.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }

    //self.inputTextField.hidden = FALSE;

}

- (void) addMessage:(Message*)msg  received:(enum ReceiveStyle)style onIndex:(int)i
{
    //self.inputTextField.hidden = FALSE;

    NSLog(@"BufferViewController: Add message %@ %d %d", msg, style, i);
    

    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
       
    if (style == ReceiveStyleAppended) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
    } else if (style == ReceiveStylePrepended) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    } else {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        //NSLog(@"Error: No handling for insert message style");
    }
    
    if (visibleRows.count > 0) {
        int lastVisibleId = [[[messages objectAtIndex:[[visibleRows lastObject] row]] messageId] intValue];
        int messageBeforeCurrentlyAddedId = [[[messages objectAtIndex:messages.count-2] messageId] intValue];
        if (lastVisibleId == messageBeforeCurrentlyAddedId) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count-1
                                                        inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else {
            [self.tableView flashScrollIndicators];
        }
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!quasselCoreConnection)
        return 0;
    
    return [messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"YYYY %d %d", indexPath.section, indexPath.row);
    
    static NSString *CellIdentifier = @"BufferTableCell";

    if (!quasselCoreConnection) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.textLabel setNumberOfLines:0];
    [cell.textLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];

    Message *message = [messages objectAtIndex:indexPath.row];
  
    cell.textLabel.text = [self textForMessage:message];

    
    if (message.messageFlag & MessageFlagHilight) {
        cell.backgroundColor = [UIColor orangeColor];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
    if (message.messageType == MessageTypeJoin ||
        message.messageType == MessageTypePart ||
        message.messageType == MessageTypeQuit ||
        message.messageType == MessageTypeMode ||
        message.messageType == MessageTypeAction ||
        message.messageType == MessageTypeKick ||
        message.messageType == MessageTypeNick ||
        message.messageType == MessageTypeNetsplitQuit ||
        message.messageType == MessageTypeNetsplitJoin ||
        message.messageType == MessageTypeTopic ||
        message.messageType == MessageTypeServer) {
        cell.textLabel.textColor = [UIColor purpleColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    if ([cell.textLabel respondsToSelector:@selector(attributedText)]) {
        if (message.messageType == MessageTypePlain) {
            int startIndex = [cell.textLabel.text rangeOfString:@"<"].location;
            int endIndex = [cell.textLabel.text rangeOfString:@">"].location;
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:cell.textLabel.text];
            //[str addAttribute:NSBackgroundColorAttributeName value:[UIColor yellowColor] range:NSMakeRange(3,5)];
            [str addAttribute:NSForegroundColorAttributeName value:[QuasselUtils uiColorFromNick:message.sender] range:NSMakeRange(startIndex+1,endIndex-startIndex-1)];
            //[str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0] range:NSMakeRange(20, 10)];
            cell.textLabel.attributedText = str;
        }
    }
    
        
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (!quasselCoreConnection)
        return 42;

    Message *message = [messages objectAtIndex:indexPath.row];

    NSString *text = [self textForMessage:message];
    
    CGSize constraint = CGSizeMake(tableView.bounds.size.width - (CELL_CONTENT_MARGIN * 2), 20000.0f);
    
    CGSize size = [text sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                   constrainedToSize:constraint
                       lineBreakMode:NSLineBreakByWordWrapping];
    // FIXME might be all a simulator bug
    
    CGFloat height = size.height;
    return height + (CELL_CONTENT_MARGIN * 2);
}

- (NSString*) textForMessage:(Message*)message
{
    if (bufferType == QueryBuffer) {
        switch(message.messageType) {
            case MessageTypeNotice:   
            case MessageTypePlain: return [NSString stringWithFormat:@"%@ <%@> %@",[QuasselUtils extractTimestamp:message],[QuasselUtils extractNick:message.sender], message.contents];
                break;
            case MessageTypeAction: return [NSString stringWithFormat:@"%@ * %@ %@",[QuasselUtils extractTimestamp:message],[QuasselUtils extractNick:message.sender], message.contents];
                break;
            case MessageTypeDayChange: return [NSString stringWithFormat:@"-{ Day changed }-"];
                break;
            case MessageTypeServer: return [NSString stringWithFormat:@"%@ * %@", [QuasselUtils extractTimestamp:message], message.contents];
                break;
            case MessageTypeError: return [NSString stringWithFormat:@"%@ Error: %@", [QuasselUtils extractTimestamp:message], message.contents];
                break;

            default:
                 return [NSString stringWithFormat:@"%@ (unhandled) %d %@ %@",[QuasselUtils extractTimestamp:message],message.messageType, [QuasselUtils extractNick:message.sender], message.contents];
        }
    } else if (bufferType == ChannelBuffer) {
        switch(message.messageType) {
            case MessageTypeNotice:   
            case MessageTypePlain: 
                return [NSString stringWithFormat:@"%@ <%@> %@",[QuasselUtils extractTimestamp:message], [QuasselUtils extractNick:message.sender], message.contents];
                break;
            case MessageTypeAction: 
                return [NSString stringWithFormat:@"%@ * %@ %@",[QuasselUtils extractTimestamp:message],[QuasselUtils extractNick:message.sender], message.contents];
                break;
            case MessageTypeJoin: 
                return [NSString stringWithFormat:@"%@ --> %@",[QuasselUtils extractTimestamp:message],message.sender];
                break;    
            case MessageTypePart: 
                return [NSString stringWithFormat:@"%@ <-- %@ (%@)",[QuasselUtils extractTimestamp:message],message.sender,message.contents];
                break;             
            case MessageTypeQuit:
                return [NSString stringWithFormat:@"%@ <-- %@ (%@)",[QuasselUtils extractTimestamp:message],message.sender, message.contents];
                break;
            case MessageTypeDayChange: 
                return [NSString stringWithFormat:@"-{ Day changed }-"];
                break;
            case MessageTypeNick: 
                return [NSString stringWithFormat:@"%@ <-> %@ is now known as %@",[QuasselUtils extractTimestamp:message],
                                          [QuasselUtils extractNick:message.sender],
                                          [QuasselUtils extractNick:message.contents]];
                break;   
            case MessageTypeNetsplitJoin: 
                return [NSString stringWithFormat:@"%@ --> %@ (after netsplit)",[QuasselUtils extractTimestamp:message],message.contents];
                break;    
            case MessageTypeNetsplitQuit:
                return [NSString stringWithFormat:@"%@ <-- %@ (netsplit)",[QuasselUtils extractTimestamp:message],message.contents];
                break;

            case MessageTypeServer:
                return [NSString stringWithFormat:@"%@ Server: %@",[QuasselUtils extractTimestamp:message],message.contents];
                break;
            case MessageTypeInfo:
                return [NSString stringWithFormat:@"%@ Info: %@",[QuasselUtils extractTimestamp:message],message.contents];
                break;
            case MessageTypeError:
                return [NSString stringWithFormat:@"%@ Error: %@",[QuasselUtils extractTimestamp:message],message.contents];
                break;
            case MessageTypeTopic:
                return [NSString stringWithFormat:@"%@ * Topic: %@",[QuasselUtils extractTimestamp:message],message.contents];
                break;
            case MessageTypeMode:
                return [NSString stringWithFormat:@"%@ * Mode: %@ %@",[QuasselUtils extractTimestamp:message],message.sender,message.contents];
                break;
            case MessageTypeKick:
                return [NSString stringWithFormat:@"%@ * Kick: %@ %@",[QuasselUtils extractTimestamp:message],message.sender,message.contents];
                break;
            case MessageTypeKill:
                return [NSString stringWithFormat:@"%@ * Kill: %@ %@",[QuasselUtils extractTimestamp:message],message.sender,message.contents];
                break;
            case MessageTypeInvite:
                return [NSString stringWithFormat:@"%@ * Invite: %@ %@",[QuasselUtils extractTimestamp:message],message.sender,message.contents];
                break;
            default:
                NSLog(@"channel msg unhandled %d %@ %@", message.messageType, message.sender, message.contents);
                return [NSString stringWithFormat:@"%@ (unhandled) %d %@ %@",[QuasselUtils extractTimestamp:message],message.messageType, message.sender, message.contents];
        }
    } else {
        switch(message.messageType) {
            case MessageTypeNotice:   
                return [NSString stringWithFormat:@"%@ Notice: %@ %@",[QuasselUtils extractTimestamp:message], message.sender, message.contents];
                break;
            case MessageTypeMode:
                return [NSString stringWithFormat:@"%@ * Mode: %@ %@",[QuasselUtils extractTimestamp:message],message.sender,message.contents];
                break;
            case MessageTypeServer:
                return [NSString stringWithFormat:@"%@ Server: %@",[QuasselUtils extractTimestamp:message],message.contents];
                break;
            case MessageTypeInfo:
                return [NSString stringWithFormat:@"%@ Info: %@",[QuasselUtils extractTimestamp:message],message.contents];
                break;
            case MessageTypeError:
                return [NSString stringWithFormat:@"%@ Error: %@ %@",[QuasselUtils extractTimestamp:message],message.sender,message.contents];
                break;
            default:
                NSLog(@"unhandled %d %@ %@", message.messageType, message.sender, message.contents);
                return [NSString stringWithFormat:@"(unhandled) %d %@",message.messageType, message.sender];
        }
    }
}

- (void) quasselSocketDidDisconnect
{
    self.quasselCoreConnection = nil;
    [self.tableView reloadData];
}

// a method that gets called in viewDidAppear and from AppDelegate ... and shows the button
- (void) showOrHideBufferListBarButtonItem
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIBarButtonItem* bufferListBarButtonItem = [(AppDelegate*)[[UIApplication sharedApplication] delegate] bufferListBarButtonItem];
        if (bufferListBarButtonItem) {
            self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:bufferListBarButtonItem,disconnectButton,nil];
        } else {
            self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:disconnectButton,nil];
        }
    }
}

- (void) forwardPressed
{
    [[AppDelegate instance] goToNextBuffer];

}

- (void) rewindPressed
{
    [[AppDelegate instance] goToPreviousBuffer];
}

- (void) disconnectPressed
{
    [quasselCoreConnection disconnect];
}

- (void) userListPressed
{
    [self performSegueWithIdentifier:@"ShowUserListSegue" sender:userListButton];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (inputTextField.isEditing) {
        [[self view] endEditing:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    };
    
    NSMutableArray *urls = [NSMutableArray array];
    
    // Split by whitespace
    NSString *text = [[messages objectAtIndex:indexPath.row] contents];
    NSArray *components = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //NSString *regExpStringFileName = [[NSBundle mainBundle] pathForResource:@"urlregexp" ofType:@"txt"];
    //NSString *regExpString = [NSString stringWithContentsOfFile:regExpStringFileName encoding:NSUTF8StringEncoding error:NULL];
    NSString *regExpString = @"(https|http)://.*";
    NSError *error = NULL;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regExpString options:NSRegularExpressionCaseInsensitive error:&error];
    [components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *string = obj;
        
        // For URLs in ()
        if ([string hasPrefix:@"("] && [string hasSuffix:@")"])
            string = [string substringWithRange:NSMakeRange(1, string.length-2)];
        
        NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [string substringWithRange:rangeOfFirstMatch];
            NSLog(@"--> %@", substringForFirstMatch);
            [urls addObject:substringForFirstMatch];
        }
    }];
    
    BufferViewTableCell *cell = (BufferViewTableCell*)[tableView cellForRowAtIndexPath:indexPath];
    messageClipboardString = cell.textLabel.text;
    messageUrls = urls;
    
    actionSheet = [[UIActionSheet alloc] init];
    actionSheet.title = nil;
    actionSheet.delegate = self;
    [actionSheet addButtonWithTitle:@"Copy to Pasteboard"];
    for (int i = 0; i < messageUrls.count; i++) {
        NSURL *URL = [NSURL URLWithString:[messageUrls objectAtIndex:i]];
        [actionSheet addButtonWithTitle:[NSString stringWithFormat:@"Open %@", URL.host]];
    }
    [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.cancelButtonIndex = messageUrls.count + 1;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [actionSheet showFromRect: [tableView cellForRowAtIndexPath:indexPath].frame inView:tableView animated: YES];
    } else {
        //[actionSheet showFromToolbar:self.navigationController.toolbar];
        [actionSheet showFromToolbar:self.navigationController.toolbar];
    }
    
    // FIXME Presenting action sheet clipped by its superview. Some controls might not respond to touches. On iPhone try -[UIActionSheet showFromTabBar:] or -[UIActionSheet showFromToolbar:] instead of -[UIActionSheet showInView:].
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath *path = self.tableView.indexPathForSelectedRow;
    if (path)
        [self.tableView deselectRowAtIndexPath:path animated:YES];
    
    if (buttonIndex == 0) {
        // Copy
        [[UIPasteboard generalPasteboard] setString:messageClipboardString];
    } else if (buttonIndex > 0 && buttonIndex <= messageUrls.count) {
        NSURL *url = [NSURL URLWithString:[messageUrls objectAtIndex:buttonIndex - 1]];
        [[UIApplication sharedApplication] performSelector:@selector(openURL:) withObject:url afterDelay:0];
    } else {
        NSLog(@"Cancel!");
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    NSIndexPath *path = self.tableView.indexPathForSelectedRow;
    if (path)
        [self.tableView deselectRowAtIndexPath:path animated:YES];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.tableView.tableFooterView == nil) {
        self.tableView.tableFooterView = inputTextField;
    }

        if (inputTextField.isEditing) {
            [[self view] endEditing:YES];
        };


}

- (void) userListUsedPressed:(IrcUser*)user
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [userListTableViewControllerPopoverController dismissPopoverAnimated:YES];
    } else {
        [userListTableViewController dismissViewControllerAnimated:YES completion:^{        }];
    }

    // Same network as current buffer's network
    NetworkId *networkId = [[quasselCoreConnection.bufferIdBufferInfoMap objectForKey:bufferId] networkId] ;
    [quasselCoreConnection openQueryBufferForUser:user onNetwork:networkId];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ShowUserListSegue"]) {
        UINavigationController *destinationVc = segue.destinationViewController;
        UserListTableViewController *ultvc = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            ultvc = segue.destinationViewController;
            userListTableViewControllerPopoverController = [(UIStoryboardPopoverSegue*)segue popoverController];
            userListTableViewController = ultvc;
        } else {
            ultvc = (UserListTableViewController*)destinationVc.topViewController;
            userListTableViewControllerPopoverController = nil;
            userListTableViewController = ultvc;
        }
        ultvc.nicks = [quasselCoreConnection ircUsersForChannelWithBufferId:bufferId];
        ultvc.callbackObject = self;
        ultvc.callbackSelector = @selector(userListUsedPressed:);

    }
}

@end
