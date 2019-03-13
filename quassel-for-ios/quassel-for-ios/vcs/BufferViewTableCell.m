// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "BufferViewTableCell.h"

@implementation BufferViewTableCell

@synthesize textLabel;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    //NSLog(@"initWithCoder");
    self = [super initWithCoder:aDecoder];
    // THis is the one getting called
    return self;
//    textLabel.userInteractionEnabled = YES;
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
//    [textLabel addGestureRecognizer:tapGesture];
//    self.userInteractionEnabled = YES;
//    [self addGestureRecognizer:tapGesture];
}

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) tapped
{

    
    // Open all of them
    
}

@end
