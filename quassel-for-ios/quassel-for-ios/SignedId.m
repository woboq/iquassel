// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "SignedId.h"
#import <objc/runtime.h>

@implementation SignedId

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] initWithInt:self.intValue];
    return copy;
}

- (id) initWithInt:(int)i_
{
    self = [super init];
    i = i_;
    return self;
}

- (id) initWithSerialization:(const char*)bytes;
{
    self = [super init];
    i = CFSwapInt32BigToHost(*(int*)(bytes));
    return self;
}

- (BOOL) isEqual:(id)object
{
    if (!object)
        return NO;
    if (![object isKindOfClass:[self class]])
        return NO;
    return [self intValue] == [object intValue]; 
}

- (int) intValue
{
    return i;
}

- (NSUInteger)hash
{
    return i;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"%s(%d)", class_getName([self class]), i];
}

- (void) serialize:(NSMutableData*)data
{
    int networkByteId = CFSwapInt32HostToBig(i);
    [data appendBytes:(char*)&networkByteId length:4];
}

@end


@implementation UserId : SignedId

@end

@implementation MsgId : SignedId

@end

@implementation AccountId : SignedId

@end


@implementation BufferId : SignedId

@end

@implementation NetworkId : SignedId

@end

@implementation IdentityId : SignedId

@end