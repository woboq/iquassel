//
//  UserListTableViewHeader.h
//  quassel-for-ios
//
//  Created by Markus Goetz on 20.04.20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserListTableViewHeader : UIView

- (void) setUp; // call before showing

@property (nonatomic, strong) IBOutlet UISwitch *showJPQSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *badgeForHilightsOnlySwitch;

 @property (nonatomic, copy, nullable) void (^jpqSwitchChangedTo)(bool);

@end

NS_ASSUME_NONNULL_END
