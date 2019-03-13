// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>

@interface ConnectingViewController : UIViewController


@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *passWord;
@property (nonatomic, strong) NSString *hostName;
@property (nonatomic) int port;

@end
