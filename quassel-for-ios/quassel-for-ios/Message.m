// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "Message.h"
#import "BufferInfo.h"
#import "QVariant.h"


@implementation Message

@synthesize messageDate;
@synthesize sender;
@synthesize contents;
@synthesize messageId;
@synthesize messageType;
@synthesize messageFlag;
@synthesize bufferInfo;

- (id) initWithSerialization:(NSData*)s bytesRead:(int*)bytesRead
{
    self = [super init];
    int offset = 0;
    
    messageId = [[MsgId alloc] initWithSerialization:[s bytes] + offset];
    offset += 4;  
    
    //ret.timestamp = new Date(stream.readUInt(32) * 1000);
    messageDate = [NSDate dateWithTimeIntervalSince1970:CFSwapInt32BigToHost(*(int*)([s bytes] + offset))];
    offset += 4;
    
    //ret.type = IrcMessage.Type.getForValue((int) stream.readUInt(32));
    messageType = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
    offset += 4;
    
    //ret.flags = stream.readByte();
    messageFlag = (enum MessageFlag)(*((char*)[s bytes] + offset));
    offset += 1;
    
    //ret.bufferInfo = (BufferInfo) QMetaTypeRegistry.instance().getTypeForName("BufferInfo").getSerializer().unserialize(stream, version);
    bufferInfo = [[BufferInfo alloc] initWithSerialization:[NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO] bytesRead:&offset];
    
    //ret.sender = (String) QMetaTypeRegistry.instance().getTypeForName("QByteArray").getSerializer().unserialize(stream, version);
    NSData *valueData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
    NSData* value = [QVariant deserializeByteArray:valueData bytesRead:&offset];
    sender = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    //NSLog(@"Decoded value %@", value);
    
    //ret.content =  SpannableString.valueOf((String)QMetaTypeRegistry.instance().getTypeForName("QByteArray").getSerializer().unserialize(stream, version));
    //NSLog(@"%d - %d = %d", s.length, offset, s.length - offset);
    valueData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
    value = [QVariant deserializeByteArray:valueData bytesRead:&offset];
    contents = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];

    //NSLog(@"Decoded value %@", value);
    
    *bytesRead += offset;
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"message(id=%@,type=%d,flags=%d,bufferInfo=%@) <%@> %@", messageId, messageType, messageFlag, bufferInfo, sender, contents];
}

- (BOOL) isEqual:(id)object
{
    if (!object)
        return NO;
    if ([self class] != [object class])
        return NO;
    return [[self messageId] isEqual:[object messageId]]; 
}

- (NSUInteger)hash
{
    return [self.messageId hash];
}

@end
