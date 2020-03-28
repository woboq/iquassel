//
//  UITextField+QuasselInputField.m
//  quassel-for-ios
//
//  Created by Markus Goetz on 28.03.20.
//

#import "UITextField+QuasselInputField.h"

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@implementation UITextField (QuasselInputField)

- (void)tabSelector {
    NSLog(@"BT tab");
    [[[AppDelegate instance] bufferViewController] tabCompleteNick];
}

@end
