// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>

@interface BufferViewTableCell : UITableViewCell
{
    UILabel *textLabel;
}

@property (nonatomic, strong) IBOutlet  UILabel *textLabel;

@end
