// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "BufferListViewController.h"
#import "AppDelegate.h"
#import "SignedId.h"
#import "BufferInfo.h"
#import "BufferViewController.h"
#import "AppState.h"

@interface BufferListViewController ()

@end

@implementation BufferListViewController

@synthesize quasselCoreConnection;
@synthesize disconnectButton;
@synthesize canReloadBufferListAndSelectLastUsedOne;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    canReloadBufferListAndSelectLastUsedOne = YES;
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    canReloadBufferListAndSelectLastUsedOne = YES;
    return self;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    canReloadBufferListAndSelectLastUsedOne = YES;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // iphone only
    if (disconnectButton) {
        disconnectButton.target = self;
        disconnectButton.action = @selector(disconnectPressed);
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!quasselCoreConnection)
        return 0;

    // FIXME: This is not the BufferViewConfig layout as in desktop, we would need to handle the BufferViewConfig properties
    return quasselCoreConnection.neworkIdList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!quasselCoreConnection)
        return 0;

    // FIXME: This is not the BufferViewConfig layout as in desktop, we would need to handle the BufferViewConfig properties
    NetworkId *idAtIndex = [quasselCoreConnection.neworkIdList objectAtIndex:section];
    // plus one for the status buffer
    return [[quasselCoreConnection.networkIdBufferIdListMap objectForKey:idAtIndex] count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self formatCell:cell atPath:indexPath];
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!quasselCoreConnection)
        return nil;
    NSString *title = [quasselCoreConnection.networkIdNetworkNameMap objectForKey:[quasselCoreConnection.neworkIdList objectAtIndex:section]];
    if (!title)
        return @"";
    return title;
}

- (NSIndexPath*) indexPathForBufferId:(BufferId*)bufferId
{
    BufferInfo *bufferInfo = [quasselCoreConnection.bufferIdBufferInfoMap objectForKey:bufferId];
    if (!bufferInfo) {
        //  can this actually happen?
        NSLog(@"indexPathForBufferId bufferId=%@ not found", bufferId);
        return nil;
    }
    
    NetworkId *networkId = bufferInfo.networkId;
    
    int section = [quasselCoreConnection.neworkIdList indexOfObject:networkId];
    
    if (bufferInfo.bufferType == StatusBuffer) {
        NSLog(@"indexPathForBufferId section=%d row=0 (name=%@)", section, bufferInfo.bufferName);
        return [NSIndexPath indexPathForRow:0 inSection:section];
    }
    
    NSMutableArray *bufferList = [quasselCoreConnection.networkIdBufferIdListMap objectForKey:networkId]; 
    int row = [bufferList indexOfObject:bufferId];
    
    if (row == NSNotFound) {
        NSLog(@"indexPathForBufferId row not found in section=%d", section);
        return nil;
    }
    
    return [NSIndexPath indexPathForRow:row+1 inSection:section];;
}

- (void) reloadRowForBufferId:(BufferId*)bufferId
{
    NSLog(@"reloadRowForBufferId %@ %@", bufferId, quasselCoreConnection);
    
    NSIndexPath *indexPath = [self indexPathForBufferId:bufferId];
    if (!indexPath) {
        NSLog(@"reloadRowForBufferId Warning Could not find/reload buffer");
        [self.tableView reloadData];
        indexPath = [self indexPathForBufferId:bufferId];
        if (!indexPath) {
            return;
        }
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self formatCell:cell atPath:indexPath];
    
    //[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) clickRowForBufferId:(BufferId*)bufferId
{
    NSLog(@"clickRowForBufferId");
    NSIndexPath *indexPath = [self indexPathForBufferId:bufferId];
    if (!indexPath) {
        NSLog(@"clickRowForBufferId Warning Could not find/click buffer");
        return;
    }

    /*
     2017-03-03 15:43:07.208696 quassel-for-ios[22172:5001241] *** Terminating app due to uncaught exception 'NSRangeException', reason: '-[UITableView _contentOffsetForScrollingToRowAtIndexPath:atScrollPosition:]: row (1) beyond bounds (1) for section (4).'

*/
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

- (void) reloadBufferListAndSelectLastUsedOne
{
    if (!canReloadBufferListAndSelectLastUsedOne)
        return;
    canReloadBufferListAndSelectLastUsedOne = NO;

    NSLog(@"============reloadBufferListAndSelectLastUsedOne==============");
    
    if (self.tableView.indexPathForSelectedRow && self.tableView.indexPathForSelectedRow.row >= 0) {
        NSLog(@"Already one selected, not doing anything");
        BufferId *bufferId = [self bufferIdForIndexPath:self.tableView.indexPathForSelectedRow];
        //[self.quasselCoreConnection fetchSomeBacklog:bufferId amount:45];
        return;
    }

    [self.tableView reloadData];
    
    BufferId* bufferId = [AppState getLastSelectedBufferId];
    if (bufferId.intValue <= 0 && self.quasselCoreConnection.visibleBufferIdsList.count > 0) {
        NSLog(@"reloadBufferListAndSelectLastUsedOne No buffer used last, first start?");
        bufferId = [self.quasselCoreConnection.visibleBufferIdsList lastObject];
    } else if (bufferId && [quasselCoreConnection.bufferIdBufferInfoMap objectForKey:bufferId] == nil) {
        bufferId = [self.quasselCoreConnection.visibleBufferIdsList lastObject];
    }
    
    if (bufferId && bufferId.intValue > 0) {
        [self clickRowForBufferId:bufferId];
        //[self.quasselCoreConnection fetchSomeBacklog:bufferId amount:45];
    }
}

- (void) goToPreviousBuffer
{
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    NSIndexPath *currentIndexPath = [self.tableView indexPathForSelectedRow];
    if (currentIndexPath == nil && app.bufferViewController) {
        currentIndexPath = [self indexPathForBufferId:app.bufferViewController.currentBufferId];
    }
    
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row-1 inSection:currentIndexPath.section];
    if (nil == [self.tableView cellForRowAtIndexPath:nextIndexPath]) {
        if (currentIndexPath.section == 0)
            nextIndexPath = nil;
        else
            nextIndexPath = [NSIndexPath indexPathForRow:[self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:currentIndexPath.section-1]-1 inSection:currentIndexPath.section-1];
    }
    if (nil == [self.tableView cellForRowAtIndexPath:nextIndexPath]) {
        int lastSection = [self.tableView.dataSource numberOfSectionsInTableView:self.tableView] - 1;
        int lastRowInLastSection = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:lastSection] - 1;
        nextIndexPath = [NSIndexPath indexPathForRow:lastRowInLastSection inSection:lastSection];
    }
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    [self.tableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [self.tableView selectRowAtIndexPath:nextIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:nextIndexPath];
}

- (void) goToNextBuffer
{
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    NSIndexPath *currentIndexPath = [self.tableView indexPathForSelectedRow];
    if (currentIndexPath == nil && app.bufferViewController) {
        currentIndexPath = [self indexPathForBufferId:app.bufferViewController.currentBufferId];
    }
    
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row+1 inSection:currentIndexPath.section];
    if (nil == [self.tableView cellForRowAtIndexPath:nextIndexPath])
        nextIndexPath = [NSIndexPath indexPathForRow:0 inSection:currentIndexPath.section+1];
    if (nil == [self.tableView cellForRowAtIndexPath:nextIndexPath])
        nextIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    [self.tableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [self.tableView selectRowAtIndexPath:nextIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:nextIndexPath];
}

- (void) formatCell:(UITableViewCell*)cell atPath:(NSIndexPath *)indexPath
{
    NetworkId *idAtIndex = [quasselCoreConnection.neworkIdList objectAtIndex:indexPath.section];
    
    if (indexPath.row == 0) {
        BufferInfo *bufferInfo =  [quasselCoreConnection.networkIdServerBufferInfoMap objectForKey:idAtIndex];
        cell.textLabel.text = @"Status";
    } else {
        //        BufferId *bufferId = [quasselCoreConnection.networkIdBufferIdListMap objectForKey:idAtIndex];
        //        BufferInfo *bufferInfo =  [[quasselCoreConnection.bufferIdBufferInfoMap objectForKey:bufferId] objectAtIndex:indexPath.row-1];
        NSArray *bufferIds = [quasselCoreConnection.networkIdBufferIdListMap objectForKey:idAtIndex];
        BufferId *bufferId = [bufferIds objectAtIndex:indexPath.row-1];
        BufferInfo *bufferInfo = [quasselCoreConnection.bufferIdBufferInfoMap objectForKey:bufferId];
        enum BufferActivity bufferActivity = [quasselCoreConnection bufferActivityForBuffer:bufferId];
        
        
        cell.textLabel.text = bufferInfo.bufferName;
        // Configure the cell...
        
        NSLog(@"formatCell buffer %d %@ %d %d", bufferId.intValue, bufferInfo.bufferName, bufferInfo.bufferActivity, bufferActivity);
        
        if (bufferActivity & BufferActivityNewMessage) {
            if (@available(iOS 13.0, *)) {
                cell.backgroundColor = [UIColor systemGray5Color];
                cell.textLabel.textColor = [UIColor systemBlueColor];
            } else {
                cell.backgroundColor = [UIColor colorWithWhite: 0.9 alpha:1];
                cell.textLabel.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.7 alpha:1];
            }
        } else if (bufferActivity & BufferActivityOtherActivity) {
            if (@available(iOS 13.0, *)) {
                cell.backgroundColor = [UIColor systemGray5Color];
                cell.textLabel.textColor = [UIColor systemGreenColor];
            } else {
                cell.backgroundColor = [UIColor colorWithWhite: 0.9 alpha:1];
                cell.textLabel.textColor = [UIColor colorWithRed:0.1 green:0.7 blue:0.1 alpha:1];
            }
        } else if (bufferActivity & BufferActivityHighlight) {
            if (@available(iOS 13.0, *)) {
                cell.backgroundColor = [UIColor systemGray5Color];
                cell.textLabel.textColor = [UIColor systemOrangeColor];
            } else {
                cell.backgroundColor = [UIColor colorWithWhite: 0.9 alpha:1];
                cell.textLabel.textColor = [UIColor orangeColor];
            }
        } else {
            if (@available(iOS 13.0, *)) {
                cell.backgroundColor = [UIColor systemBackgroundColor];
                cell.textLabel.textColor = [UIColor labelColor];
            } else {
               cell.backgroundColor = [UIColor clearColor];
                cell.textLabel.textColor = [UIColor blackColor];
            }
        }
    }
}

#pragma mark - Table view delegate

- (BufferId*) bufferIdForIndexPath:(NSIndexPath *)indexPath
{
    NetworkId *idAtIndex = [quasselCoreConnection.neworkIdList objectAtIndex:indexPath.section];
    BufferInfo *bufferInfo = nil;
    if (indexPath.row == 0) {
        bufferInfo =  [quasselCoreConnection.networkIdServerBufferInfoMap objectForKey:idAtIndex];
        return bufferInfo.bufferId;
    } else {
        BufferId *bufferId = [[quasselCoreConnection.networkIdBufferIdListMap objectForKey:idAtIndex] objectAtIndex:indexPath.row-1];
        return bufferId;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        BufferViewController *bufferViewController = [app bufferViewController];
        if (bufferViewController) {
//            NetworkId *idAtIndex = [quasselCoreConnection.neworkIdList objectAtIndex:indexPath.section];
//            BufferInfo *bufferInfo = nil;
            BufferId *bufferId = [self bufferIdForIndexPath:indexPath];
//            if (indexPath.row == 0) {
//                bufferInfo =  [quasselCoreConnection.networkIdServerBufferInfoMap objectForKey:idAtIndex];
//                bufferViewController.quasselCoreConnection = quasselCoreConnection;
                [bufferViewController setCurrentBufferId:bufferId];
                [AppState setLastSelectedBufferId:bufferId];
//            } else {
//                BufferId *bufferId = [[quasselCoreConnection.networkIdBufferIdListMap objectForKey:idAtIndex] objectAtIndex:indexPath.row-1];
//                bufferViewController.quasselCoreConnection = quasselCoreConnection;
//                [bufferViewController setCurrentBufferId:bufferId];
//                [AppState setLastSelectedBufferId:bufferId];
//            }
        }
    } else {
        //..  if already visible then just update?
        UINavigationController *navigationController = (UINavigationController *)self.navigationController;
        if ([navigationController.topViewController isKindOfClass:BufferViewController.class]) {
            BufferId *bufferId = [self bufferIdForIndexPath:indexPath];
            BufferViewController *bufferViewController = [app bufferViewController];
            [bufferViewController setCurrentBufferId:bufferId];
            [AppState setLastSelectedBufferId:bufferId];
        } else {
            [self performSegueWithIdentifier:@"ShowBuffer" sender:self];
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void) quasselSocketDidDisconnect
{
    self.canReloadBufferListAndSelectLastUsedOne = YES;
    self.quasselCoreConnection = nil;
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
    NSLog(@"BufferListViewController viewWillAppear");

    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
    } else {
        NSLog(@"FIXME Add disconnect button");
        // Change
        self.navigationItem.hidesBackButton = YES;
        [self.tableView reloadData];
        
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"BufferListViewController viewDidAppear");
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
    } else {
        [self reloadBufferListAndSelectLastUsedOne];
        if ([self.tableView numberOfRowsInSection:0] > 0) {
            BufferId *bufferId = [self bufferIdForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            //[self.quasselCoreConnection fetchSomeBacklog:bufferId amount:45];
        }
    }
    
}

- (void) viewDidDisappear:(BOOL)animated
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
    } else {
        self.navigationItem.hidesBackButton = NO;
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Not done on ipad, on ipad everything is in didSelectRowAtIndexPath
    } else {
        if ([segue.identifier isEqualToString:@"ShowBuffer"]) {
            BufferId *bufferId = [self bufferIdForIndexPath:self.tableView.indexPathForSelectedRow];

            BufferViewController *vc = segue.destinationViewController;
            vc.quasselCoreConnection = quasselCoreConnection;
            [vc setCurrentBufferId:bufferId];
            [AppState setLastSelectedBufferId:bufferId];
        }
    }
}

- (void) disconnectPressed
{
    [quasselCoreConnection disconnect];
}


@end
