// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "QBoolean.h"

@implementation QBoolean
@synthesize value;

- (id) initWithValue:(BOOL)v
{
    self = [super init];
    value = v;
    return self;
}

- (NSString *)description
{
    if (value)
        return @"YES";
    else {
        return @"NO";
    }
}

@end
