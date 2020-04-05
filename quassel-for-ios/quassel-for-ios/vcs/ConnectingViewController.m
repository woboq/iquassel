// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "ConnectingViewController.h"
#import "QuasselCoreConnection.h"
#import "AppDelegate.h"
#import "BufferListViewController.h"
#import "ErrorViewController.h"

@interface ConnectingViewController ()

@end

@implementation ConnectingViewController

@synthesize userName;
@synthesize passWord;
@synthesize hostName;
@synthesize port;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    NSLog(@"<------- ConnectingViewController viewWillAppear");
    self.navigationItem.hidesBackButton = YES;

    self.view.backgroundColor = [UIColor systemBackgroundColor];
}

- (void) viewDidAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    NSLog(@"<------- ConnectingViewController viewDidAppear");
    self.navigationItem.hidesBackButton = YES;

    NSLog(@"ConnectingViewController viewDidAppear");
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [app startConnectingTo:hostName port:port userName:userName passWord:passWord];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    NSLog(@"ConnectingViewController prepareForSegue %@", segue.identifier);
    
    if ([segue.destinationViewController isMemberOfClass:BufferListViewController.class]) {
        // True on iPhone
        BufferListViewController *vc = segue.destinationViewController;
        vc.quasselCoreConnection = app.quasselCoreConnection;
    } else if ([segue.destinationViewController isMemberOfClass:BufferViewController.class]) {
        // iPad
        BufferViewController *vc = segue.destinationViewController;
        vc.quasselCoreConnection = app.quasselCoreConnection;
    } else if ([segue.destinationViewController isMemberOfClass:ErrorViewController.class]) {
        
    } else {
        NSLog(@"Unknown segue %@, destination is %@!", segue.identifier, segue.destinationViewController);
    }
}

@end
