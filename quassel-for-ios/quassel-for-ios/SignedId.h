// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>

@interface SignedId : NSObject <NSCopying> 
{
    int i;
}

- (id)copyWithZone:(NSZone *)zone;

- (id) initWithInt:(int)i;
- (id) initWithSerialization:(const char*)bytes;


- (int) intValue;

- (NSUInteger)hash;

- (BOOL) isEqual:(id)object;

- (void) serialize:(NSMutableData*)data;

@end


@interface UserId : SignedId

@end

@interface MsgId : SignedId

@end

@interface AccountId : SignedId

@end

@interface BufferId : SignedId

@end

@interface NetworkId : SignedId

@end

@interface IdentityId : SignedId

@end