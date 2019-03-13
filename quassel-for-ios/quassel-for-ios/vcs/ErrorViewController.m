// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "ErrorViewController.h"
#import "AppDelegate.h"
#import "LoginViewController.h"

@interface ErrorViewController ()

@end

@implementation ErrorViewController

@synthesize errorLabel;
@synthesize errorString;
 
@synthesize reconnectButton; 

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
    
    reconnectButton = [[UIBarButtonItem alloc] initWithTitle:@"Reconnect" style:UIBarButtonItemStyleDone target:self action:@selector(reConnect)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) viewDidAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    self.navigationController.viewControllers = [NSArray arrayWithObjects:[self.navigationController.viewControllers objectAtIndex:0],self , nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    //self.navigationController.viewControllers = [NSArray arrayWithObjects:[self.navigationController.viewControllers objectAtIndex:0],self , nil];

    if (errorString) {
        errorLabel.text = errorString;
    } else {
        AppDelegate *app = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        errorLabel.text = app.lastErrorMessage;
    }
    
    self.navigationItem.rightBarButtonItem = reconnectButton;
}

- (void) viewWillDisappear:(BOOL)animated
{
    self.errorString = nil;
    self.errorLabel.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void) reConnect
{
    UINavigationController *nc = self.navigationController;
    LoginViewController *loginVc = [nc.viewControllers objectAtIndex:0];
    loginVc.autoConnect = YES;
    nc.viewControllers = [NSArray arrayWithObjects:loginVc,nil];
    //[self.navigationController popViewControllerAnimated:YES];
    NSArray *tmp = [nc popToRootViewControllerAnimated:NO];

// FIXME now call the thing async again?
    // ah no that might not help....
    // but why why why does it not pop?

    NSString *x = [[NSString stringWithFormat:@"%@", nc.viewControllers] stringByReplacingOccurrencesOfString:@"<" withString:@"-"];
    errorLabel.text = [NSString stringWithFormat:@"DOING RECONNECT >%@< %@ %lu >%@<", tmp, nc,
                       (unsigned long)nc.viewControllers.count, x];
    NSLog(@"------> %@", errorLabel.text);
}

@end
