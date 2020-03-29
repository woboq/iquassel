// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController


@property (nonatomic,strong) IBOutlet UITextField *userNameField;
@property (nonatomic,strong) IBOutlet UITextField *passWordField;
@property (nonatomic,strong) IBOutlet UITextField *hostNameField;
@property (nonatomic,strong) IBOutlet UITextField *portField;

@property (nonatomic,strong) IBOutlet UIBarButtonItem *connectButton;

@property (nonatomic,strong) IBOutlet UILabel *errroLabel;


@property (nonatomic,strong) IBOutlet UIButton *quasselButton;
@property (nonatomic,strong) IBOutlet UIButton *woboqButton;

@property (nonatomic) BOOL autoConnect;




@end
