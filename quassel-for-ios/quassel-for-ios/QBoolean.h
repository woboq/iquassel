// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>

@interface QBoolean : NSObject
{
    BOOL value;
}

@property (nonatomic) BOOL value;

- (id) initWithValue:(BOOL)v;

@end
