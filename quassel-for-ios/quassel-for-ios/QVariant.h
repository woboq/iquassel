// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>
//#import "QBoolean.h"

@class Message;
@class QBoolean;
@class BufferInfo;
//@class NetworkId;
//@class IdentityId;
#import "SignedId.h"

@interface QVariant : NSObject
{
    // Qt types
    NSDictionary *dict;
    NSString *string;
    QBoolean *boolean;
    NSNumber *integer;
    NSArray *list;
    NSData *byteArray;
    
    // Quassel types
    Message *message;
    BufferInfo *bufferInfo;
    NetworkId *networkId;
    IdentityId *identityId;
    BufferId *bufferId;
    MsgId *msgId;
}

@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) QBoolean *boolean;
@property (nonatomic, strong) NSNumber *integer;
@property (nonatomic, strong) NSArray *list;
@property (nonatomic, strong) NSNumber *msecsSinceMidnight;


@property (nonatomic, strong) NSData *byteArray;
@property (nonatomic, strong) NetworkId *networkId;
@property (nonatomic, strong) IdentityId *identityId;
@property (nonatomic, strong) BufferId *bufferId;
@property (nonatomic, strong) MsgId *msgId;

@property (nonatomic, strong) Message *message;
@property (nonatomic, strong) BufferInfo *bufferInfo;

- (id) initWithQVariantMap:(NSDictionary*)dict;
- (id) initWithQVariantList:(NSArray*)list;
- (id) initWithString:(NSString*)str;
- (id) initWithQBoolean:(QBoolean*)b;
- (id) initWithBoolean:(BOOL)b;
- (id) initWithInteger:(NSNumber*)i;
- (id) initWithInt:(int)i;
- (id) initWithBufferId:(BufferId*)i;
- (id) initWithBufferInfo:(BufferInfo*)bI;
- (id) initWithMsgId:(MsgId*)i;

;

- (id) initWithSerialization:(NSData*)s bytesRead:(int*)bytesRead;

- (NSData*) serialize;

- (NSString*)asStringFromStringOrByteArray;

- (int) intValue;

+ (NSData*) deserializeByteArray:(NSData*)valueData bytesRead:(int*)bytesRead;
+ (NSData*) serializeString:(NSString*)s;


@end
