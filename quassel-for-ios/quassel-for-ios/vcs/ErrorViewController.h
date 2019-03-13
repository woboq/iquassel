// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>

@interface ErrorViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *errorLabel;
@property (nonatomic, strong) NSString *errorString;

@property (nonatomic, strong) UIBarButtonItem *reconnectButton;

- (void) reConnect;

@end
