//
//  UserListTableViewHeader.m
//  quassel-for-ios
//
//  Created by Markus Goetz on 20.04.20.
//

#import "UserListTableViewHeader.h"

@implementation UserListTableViewHeader

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void) setUp
{
    [self.showJPQSwitch addTarget:self action:@selector(jpqChanged:) forControlEvents:UIControlEventValueChanged];
    [self.badgeForHilightsOnlySwitch addTarget:self action:@selector(highlightsOnlyChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)jpqChanged:(id)sender {
    BOOL state = [sender isOn];
    NSLog(state ? @"ON" : @"OFF");
    if (self.jpqSwitchChangedTo) {
        self.jpqSwitchChangedTo(state);
    }
}

- (void)highlightsOnlyChanged:(id)sender {
    BOOL state = [sender isOn];
    NSLog(state ? @"ON" : @"OFF");
    if (self.badgeForHilightsOnlySwitchChangedTo) {
        self.badgeForHilightsOnlySwitchChangedTo(state);
    }
}
@end
