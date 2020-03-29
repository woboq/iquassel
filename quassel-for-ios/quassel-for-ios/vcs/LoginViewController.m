// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "LoginViewController.h"
#import "ConnectingViewController.h"
#import "PDKeychainBindings.h"
#import "AppDelegate.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize userNameField;
@synthesize passWordField;
@synthesize hostNameField;
@synthesize portField;
@synthesize connectButton;
@synthesize errroLabel;
@synthesize autoConnect;

@synthesize quasselButton;
@synthesize woboqButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }

    return self;
}

- (void) awakeFromNib{
    [super awakeFromNib];
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
//    AppDelegate *app =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
//    self.splitViewController.delegate = app;
    autoConnect = NO;

    self.navigationController.toolbarHidden = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) doAutoConnect
{
    //UIView setAnimationsEnabled:NO];
    NSLog(@"<------- doAutoConnect");
    [self performSegueWithIdentifier:@"ConnectSegue" sender:connectButton];
    //[UIView setAnimationsEnabled:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.navigationItem.hidesBackButton = YES;

    if (userNameField.text.length == 0) {
        PDKeychainBindings *kc = [PDKeychainBindings sharedKeychainBindings];
        userNameField.text = [kc objectForKey:@"userName"];
        passWordField.text = [kc objectForKey:@"passWord"];
        hostNameField.text = [kc objectForKey:@"hostName"];
        if ([kc objectForKey:@"port"])
            portField.text = [kc objectForKey:@"port"];
        else
            portField.text = @"4242";
    }
    
    {
        // We set this now, if we ever switch to in-app purchase then the "old" users will still be Pro
        // because they had paid.
        PDKeychainBindings *kc = [PDKeychainBindings sharedKeychainBindings];
        [kc setObject:@"Pro" forKey:@"iQuasselVersion"];
    }
    
    if (autoConnect) {
        autoConnect = NO;
        [self performSelector:@selector(doAutoConnect) withObject:nil afterDelay:0];
    }
    
    if (errroLabel.text.length == 0) {
        errroLabel.numberOfLines = 0;
        //errroLabel.textAlignment = UITextAlignmentCenter;
        //errroLabel.lineBreakMode = UILineBreakModeWordWrap;
        errroLabel.text = @"Welcome to iQuassel!\n\nThis is a client for the Quassel IRC system.\n\nYou need an account on a Quassel core to use it.\n\nIf you need help, we are on \n#woboquassel on irc.freenode.net\n\nGitHub: https://github.com/woboq/iquassel";
    }
    errroLabel.textColor = [UIColor labelColor];
    errroLabel.hidden = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    
    [quasselButton addTarget:self action:@selector(quasselButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [woboqButton addTarget:self action:@selector(woboqButtonTouched) forControlEvents:UIControlEventTouchUpInside];

    errroLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(errorLabelTouched)];
    [errroLabel addGestureRecognizer:tapGesture];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void) quasselButtonTouched
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.quassel-irc.org/"]];
}

- (void) woboqButtonTouched
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://woboq.com/?utm_source=iquassel&utm_medium=iquassel&utm_campaign=mainwindow"]];
    
}

- (void) errorLabelTouched
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/woboq/iquassel"]];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ConnectSegue"]) {
        PDKeychainBindings *kc = [PDKeychainBindings sharedKeychainBindings];
        [kc setObject:userNameField.text forKey:@"userName"];
        [kc setObject:passWordField.text forKey:@"passWord"];
        [kc setObject:hostNameField.text forKey:@"hostName"];
        [kc setObject:portField.text forKey:@"port"];
        
        ConnectingViewController *vc = segue.destinationViewController;
        vc.userName = userNameField.text;
        vc.passWord = passWordField.text;
        vc.hostName = hostNameField.text;
        vc.port = [portField.text intValue];
    }
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
    } else {
        errroLabel.hidden = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    }
}

@end
