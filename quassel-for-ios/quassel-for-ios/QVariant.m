// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "AppDelegate.h"
#import "QVariant.h"
#import "BufferInfo.h"  
#import "Message.h"
#import "QBoolean.h"
#import "SignedId.h"

@implementation QVariant

@synthesize dict;
@synthesize string;
@synthesize boolean;
@synthesize integer;
@synthesize list;
@synthesize msecsSinceMidnight;

@synthesize message;
@synthesize bufferInfo;
@synthesize byteArray;
@synthesize networkId;
@synthesize identityId;
@synthesize bufferId;
@synthesize msgId;

// http://qt-project.org/doc/qt-4.8/datastreamformat.html
// https://github.com/sandsmark/QuasselDroid/blob/master/QuasselDroid/src/main/java/com/iskrembilen/quasseldroid/qtcomm/QMetaType.java?source=cc

// FIXME build some length assertions in

- (id) initWithSerialization:(NSData*)s  bytesRead:(int*)bytesRead
{
    self = [super init];

    if (s && s.length == 5) {
        NSLog(@"Reading null serialization of identifier %d", CFSwapInt32BigToHost(*(int*)[s bytes]));
        return self;
    }

    if (!s || s.length <= 5) {
        NSLog(@"Reading null serialization (length=%d)", s.length);
        return self;
    }
    
    
    // read 4 bytes identifier
    int identifier = CFSwapInt32BigToHost(*(int*)[s bytes]);
    if (identifier == 8) {
//        // variant dictionary
        //NSLog(@"Deserializing variant map");
        
        int offset = 4 + 1; // int identifier, null byte
        
        int bytesForStringVariantMap = 0;
        NSData *stringVariantMapData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
        dict = [self deserializeStringVariantMap:stringVariantMapData bytesRead:&bytesForStringVariantMap];
        offset += bytesForStringVariantMap;
        
        *bytesRead = offset;
        
        
    } else if (identifier == 9) {
        // qvariant list
        int offset = 4 + 1; // int identifier, null byte
        int entryCount = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
        //NSLog(@"array with %d entries", entryCount);
        offset += 4;

        NSMutableArray *array = [NSMutableArray arrayWithCapacity:entryCount];
        for (int i = 0; i < entryCount; i++) {
            NSData *valueData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
            int bytesForValue = 0;
            QVariant *value = [[QVariant alloc] initWithSerialization:valueData bytesRead:&bytesForValue];
#ifdef QUASSEL_DEBUG_PROTOCOL
            NSLog(@"Decoded value %@", value);
#endif

            offset += bytesForValue;
            
            [array addObject:value];
        }
        *bytesRead = offset;
        
        list = array;
    } else if (identifier == 11) {
        // qstring list
        int offset = 4 + 1; // int identifier, null byte
        int entryCount = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
        //NSLog(@"string array with %d entries", entryCount);
        offset += 4;
        
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:entryCount];
        for (int i = 0; i < entryCount; i++) {
            NSData *valueData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
            int bytesForValue = 0;
            //QVariant *value = [[QVariant alloc] initWithSerialization:valueData bytesRead:&bytesForValue];
            NSString *value = [self deserializeString:valueData bytesRead:&bytesForValue];
            //NSLog(@"Decoded string value %@", value);
            
            offset += bytesForValue;
            
            [array addObject:value];
        }
        *bytesRead = offset;
        
        list = array;
        
    } else if (identifier == 2) {
        // integer
       // NSLog(@"Deserializing integer");
        int offset = 4 + 1; // int identifier, null byte
        int i = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
        integer = [NSNumber numberWithInteger:i];
        *bytesRead = offset + 4;
    } else if (identifier == 133) {
        // integer
        //NSLog(@"Deserializing ushort");
        int offset = 4 + 1; // int identifier, null byte
        ushort i = CFSwapInt16BigToHost(*(int*)([s bytes] + offset));
        //integer = [NSNumber numberWithInteger:i];
        *bytesRead = offset + 2;
    } else if (identifier == 3) {
        // integer
       // NSLog(@"Deserializing unsigned integer");
        int offset = 4 + 1; // int identifier, null byte
        unsigned int i = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
        integer = [NSNumber numberWithUnsignedInteger:i];
        *bytesRead = offset + 4;
    } else if (identifier == 10) {
        // string
        //NSLog(@"Deserializing string");
        int offset = 4 + 1; // int identifier, null byte
        NSData *stringData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
        int bytesForString = 0;
        string = [self deserializeString:stringData bytesRead:&bytesForString];
        *bytesRead = offset + bytesForString;
    } else if (identifier == 12) {
        // integer
        //NSLog(@"Deserializing byte array");
        int offset = 4 + 1; // int identifier, null byte
        byteArray = [QVariant deserializeByteArray: [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO] bytesRead:&offset];
        *bytesRead = offset;     
    } else if (identifier == 15) {
        //NSLog(@"FIXME Deserializing time");
        //        Time (QTime) - Milliseconds since midnight (quint32) FIXME
        int offset = 4 + 1; // int identifier, null byte
        msecsSinceMidnight = [NSNumber numberWithUnsignedInt:CFSwapInt32BigToHost(*(int*)([s bytes] + offset))];
        offset += 4;
        *bytesRead = offset;
        
    } else if (identifier == 16) {
        // boolean
        //NSLog(@"Deserializing date/time");
        int offset = 4 + 1; // int identifier, null byte
        
//        Date (QDate) - Julian day (quint32) FIXME
        unsigned int julianDay = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
        offset += 4;

//        Time (QTime) - Milliseconds since midnight (quint32) FIXME
        unsigned int _msecsSinceMidnight = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
        offset += 4;
        
//        0 for Qt::LocalTime, 1 for Qt::UTC (quint8) FIXME
        
        offset += 1;
        *bytesRead = offset;
        
        // FIXME
        //NSLog(@"Deserializing date/time %d %d", julianDay, _msecsSinceMidnight / 1000 / 60 / 60);


    } else if (identifier == 1) {
        // boolean
        //NSLog(@"Deserializing boolean");
        BOOL b = *(char*)([s bytes] + 4 + 1) == 0x01 ? YES : NO;
        boolean = [[QBoolean alloc] initWithValue:b];
        *bytesRead = 6;
    } else if (identifier == 127) {
        //NSLog(@"Deserializing user type");
        int offset = 4 + 1; // int identifier, null byte
        int bytesForUserTypeIdentifier = 0;
        NSData *stringData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
        char *userTypeIdentifier = [self deserializeCharString:stringData bytesRead:&bytesForUserTypeIdentifier]; 
        //NSLog(@"Deserializing user type %s", userTypeIdentifier);
        offset += bytesForUserTypeIdentifier;
        
        if (0 == strcmp("NetworkId", userTypeIdentifier)) {
            unsigned int i = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
            networkId = [[NetworkId alloc] initWithInt:i];
            offset += 4;
        } else if (0 == strcmp("IdentityId", userTypeIdentifier)) {
            unsigned int i = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
            identityId = [[IdentityId alloc] initWithInt:i];
            offset += 4;
        } else if (0 == strcmp("BufferId", userTypeIdentifier)) {
            bufferId = [[BufferId alloc] initWithSerialization:[s bytes] + offset];
            offset += 4;
        } else if (0 == strcmp("MsgId", userTypeIdentifier)) {
            msgId = [[MsgId alloc] initWithSerialization:[s bytes] + offset];
            offset += 4;
        } else if (0 == strcmp("Identity", userTypeIdentifier)) {
            //This is a Map<String, QVariant>
            int bytesForStringVariantMap = 0;
            NSData *stringVariantMapData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
            dict = [self deserializeStringVariantMap:stringVariantMapData bytesRead:&bytesForStringVariantMap];
            offset += bytesForStringVariantMap;
        } else if (0 == strcmp("BufferInfo", userTypeIdentifier)) {
            NSData *valueData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
            //NSLog(@"valueData.length = %d, offset = %d", valueData.length, offset);
            bufferInfo = [[BufferInfo alloc] initWithSerialization:valueData bytesRead:&offset];

        } else if (0 == strcmp("Message", userTypeIdentifier)) {
            NSData *valueData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
            //NSLog(@"valueData.length = %d, offset = %d", valueData.length, offset);
            message = [[Message alloc] initWithSerialization:valueData bytesRead:&offset];

        } else if (0 == strcmp("Network::Server", userTypeIdentifier)) {
            /*
             public NetworkServer unserialize(QDataInputStream stream, DataStreamVersion version) throws IOException, EmptyQVariantException {
             Map<String, QVariant<?>> map = (Map<String, QVariant<?>>)
             QMetaTypeRegistry.instance().getTypeForName("QVariantMap").getSerializer().unserialize(stream, version);
             
             return new NetworkServer((String)map.get("Host").getData(),
             (Long)map.get("Port").getData(),
             (String)map.get("Password").getData(),
             
             (Boolean)map.get("UseSSL").getData(),
             (Integer)map.get("sslVersion").getData(),
             
             (Boolean)map.get("UseProxy").getData(),
             (String)map.get("ProxyHost").getData(),
             (Long)map.get("ProxyPort").getData(),
             (Integer)map.get("ProxyType").getData(),
             (String)map.get("ProxyUser").getData(),
             (String)map.get("ProxyPass").getData()
             );*/
#ifdef QUASSEL_DEBUG_PROTOCOL
            NSLog(@"Deserializing Network::Server");
#endif

            int bytesForStringVariantMap = 0;
            NSData *stringVariantMapData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
            dict = [self deserializeStringVariantMap:stringVariantMapData bytesRead:&bytesForStringVariantMap];
            offset += bytesForStringVariantMap;
            
            
            
        } else {
            NSLog(@"FIXME Unknown user type %s <%@>", userTypeIdentifier, s.base64Encoding);
        }
        
        
        free(userTypeIdentifier);
        
        
        *bytesRead = offset;
    } else if (identifier == 7) {
        //NSLog(@"Deserializing char [FIXME] %@", s.base64Encoding);
//        int offset = 4 + 1; // int identifier, null byte
//        int i = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
//        int j = (*(int*)([s bytes] + offset));
//        char c = i;
//        char h = j;
//        NSLog(@"Deserializing char -> %c %c", c, h);
//        *bytesRead = offset + 4 + 7; // the 7 is invented, no idea why this is how it is

        // AAAABwAAbgAAAAoA/////w==
        // [0][0][0][7][0][0]n[0][0][0][10][0][255][255][255][255]

        // AAAABwAAdAAAAAoA/////w==
        // [0][0][0][7][0][0]t[0][0][0][10][0][255][255][255][255]

        int offset = 4 + 1; // int identifier, null byte
        int i = CFSwapInt16BigToHost(*(int*)([s bytes] + offset));
        char c = i;
#ifdef QUASSEL_DEBUG_PROTOCOL
        NSLog(@"Deserializing char -> %c", c);
#endif
        self.string = [NSString stringWithFormat:@"%c", c];
        //*bytesRead = offset + 4 + 7; // the 7 is invented, no idea why this is how it is
        *bytesRead = offset + 2;

    } else if (identifier == 143) {
        NSLog(@"FIXME Unknown serialization identifier %d WE HAVE SEEN IT BEFORE WHEN CONNECTING?", identifier);
    } else {
        NSLog(@"FIXME Unknown serialization identifier %d?", identifier);
    }
        
    return self;
}

- (id) initWithQVariantMap:(NSDictionary*)d
{
    self = [super init];
    dict = d;
    return self;
}

- (id) initWithQVariantList:(NSArray*)l
{
    self = [super init];
    list = l;
    return self;
}

- (id) initWithString:(NSString *)str
{
    self = [super init];
    string = str;
    return self;
}

- (id) initWithQBoolean:(QBoolean *)b
{
    self = [super init];
    boolean = b;
    return self;
}

- (id) initWithBoolean:(BOOL)b
{
    self = [super init];
    boolean = [[QBoolean alloc] initWithValue:b];
    return self;
}

- (id) initWithInteger:(NSNumber *)i
{
    self = [super init];
    integer = i;
    return self;
}

- (id) initWithInt:(int)i {
    self = [super init];
    integer = [NSNumber numberWithInt:i];
    return self;
}

- (id) initWithBufferId:(BufferId*)i
{
    self = [super init];
    bufferId = i;
    return self;
}

- (id) initWithBufferInfo:(BufferInfo*)bI
{
    self = [super init];
    bufferInfo = bI;
    return self;
}

    
- (id) initWithMsgId:(MsgId*)i
{
    self = [super init];
    msgId = i;
    return self;
}


+ (NSData*) deserializeByteArray:(NSData*)valueData bytesRead:(int*)bytesRead
{
    unsigned int length = CFSwapInt32BigToHost(*(int*)([valueData bytes]));
    *bytesRead += 4;
    //NSLog(@"Deserializing byte array with %u bytes", length);
    if (length == 0xFFFFFFFF)
        return [NSData data];
    
    NSData *retData = [NSData dataWithBytes:[valueData bytes] + 4 length:length];
    *bytesRead += length;
    return retData;
}

- (NSDictionary*) deserializeStringVariantMap:(NSData*)s bytesRead:(int*)bR

{
    // variant dictionary
    //NSLog(@"Deserializing variant map");
    
    int offset = 0;
    int entryCount = CFSwapInt32BigToHost(*(int*)([s bytes] + offset));
    //NSLog(@"map with %d entries", entryCount);
    offset += 4;
    
    NSMutableDictionary *dictonary = [NSMutableDictionary dictionaryWithCapacity:entryCount];
    
    for (int i = 0; i < entryCount; i++) {
        
        // Read key
        NSData *keyData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
        int bytesForKey = 0;
        NSString *key = [self deserializeString:keyData bytesRead:&bytesForKey];

        offset += bytesForKey;

        
        NSData *valueData = [NSData dataWithBytesNoCopy:(void*)[s bytes] + offset length:s.length-offset freeWhenDone:NO];
        int bytesForValue = 0;
        QVariant *value = [[QVariant alloc] initWithSerialization:valueData bytesRead:&bytesForValue];

#ifdef QUASSEL_DEBUG_PROTOCOL
        NSLog(@"Decoded key (%d) %@ ", bytesForKey, key);
        NSLog(@"Decoded value %@", value);
#endif

        offset += bytesForValue;
        
        [dictonary setValue:value forKey:key];
    }
    *bR = offset;
    
    return dictonary;
    
}


- (char*) deserializeCharString:(NSData*)data bytesRead:(int*)bR
{
    int length = CFSwapInt32BigToHost(*(int*)[data bytes]);
    *bR = 4 + length;
    
    char *ret = malloc(length+1);
    memcpy(ret, [data bytes] + 4, length);
    ret[length] = 0;
    return ret;
}

- (NSString*) deserializeString:(NSData*)data bytesRead:(int*)bR
{
    // Read length
    unsigned int length = CFSwapInt32BigToHost(*(int*)[data bytes]);
    //NSLog(@"Deserializing string with %d bytes", length);
    
    *bR += 4;
    
    if (length == 0xFFFFFFFF)
        return @"";
    
    *bR += length;
        
    // Read string
    NSString *s = 
    [[NSString alloc] initWithBytes:[data bytes] + 4 
                             length:length
                                        encoding:NSUTF16BigEndianStringEncoding];
    //NSLog(@"=> %@", s);

    return s;
}
                                                             
                                                             
                                                             
                                                             
                                                             
+ (NSData*) serializeString:(NSString*)s
{
    // FIXME
    
    //- (BOOL)getCString:(char *)buffer maxLength:(NSUInteger)maxBufferCount encoding:(NSStringEncoding)encoding
    // NSUTF16StringEncoding or NSUTF16BigEndianStringEncoding
    
    //NSData *utf16be = [s 
//    stream.writeUInt(data.getBytes("UTF-16BE").length, 32);
//    stream.write(data.getBytes("UTF-16BE"));
    
    int capacity = s.length*2+2;
    NSMutableData *data = [NSMutableData dataWithLength:capacity];
    BOOL b = [s getCString:[data mutableBytes] maxLength:capacity encoding:NSUTF16BigEndianStringEncoding];
    if (!b) {
        NSLog(@"serializeString String failure, capacity was %d (now %lu)", capacity, (unsigned long)data.length);
    } else {
        [data setLength:capacity];
        //NSLog(@"serializeString string of length %d serialized to %d bytes (now %d): %@", s.length, capacity, data.length, data);
    }
    
    // Remove 0 byte
    NSRange r;
    r.location = capacity - 2;
    r.length = 2;
    [data replaceBytesInRange:r withBytes:NULL length:0];
    
    NSMutableData *returnData = [NSMutableData dataWithCapacity:data.length + 4];
    
    int length = CFSwapInt32HostToBig(data.length);
    [returnData appendBytes:(char*)&length length:4];
    [returnData appendData:data];
    return returnData;
}

- (NSData*) serialize
{
    NSMutableData *data = [NSMutableData data];
    if (dict) {
        // append ID
        int identifier = CFSwapInt32HostToBig(8);
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        // append length
        int count = CFSwapInt32HostToBig(dict.count);
        [data appendBytes:(char*)&count length:4];
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [data appendData:[QVariant serializeString:key]];
            [data appendData:[obj serialize]];
        }];
        //NSLog(@"Serialized %d bytes - %d item qvariant map", data.length, dict.count);
    } else if (list) {
        int identifier = CFSwapInt32HostToBig(9);
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        int count = CFSwapInt32HostToBig(list.count);
        [data appendBytes:(char*)&count length:4];
        [list enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            //NSLog(@"List serialization: Item %d %@", i, obj);
            [data appendData:[obj serialize]];
        }];
        //NSLog(@"Serialized %d bytes - %d item qvariant list", data.length, list.count);

    } else if (integer) {
        int identifier = CFSwapInt32HostToBig(2);
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        int i = CFSwapInt32HostToBig([integer intValue]);
        [data appendBytes:(char*)&i length:4];
        //NSLog(@"Serialized %d bytes - integer of value %d", data.length, [integer intValue]);
    } else if (string) {
        int identifier = CFSwapInt32HostToBig(10);
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        [data appendData:[QVariant serializeString:string]];
        //NSLog(@"Serialized %d bytes - string %@", data.length, string);
    } else if (boolean) {
        int identifier = CFSwapInt32HostToBig(1);
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        if (boolean.value)
            [data appendBytes:"\x01" length:1];
        else
            [data appendBytes:"\x00" length:1];
        //NSLog(@"Serialized %d bytes - boolen of value %@", data.length, boolean.value ? @"TRUE" : @"FALSE");
    } else if (bufferId) {
        int identifier = CFSwapInt32HostToBig(127); // user type
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        [self serialize:"BufferId" into:data];
        [bufferId serialize:data];
        //NSLog(@"Serialized %d bytes - BufferId of value %d", data.length, [bufferId intValue]);
        
    } else if (bufferInfo) {
        int identifier = CFSwapInt32HostToBig(127); // user type
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        [self serialize:"BufferInfo" into:data];
        [bufferInfo serialize:data];
        //NSLog(@"Serialized %d bytes - BufferId of value %d", data.length, [bufferId intValue]);        
        
        
    } else if (msgId) {
        int identifier = CFSwapInt32HostToBig(127); // user type
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        [self serialize:"MsgId" into:data];
        [msgId serialize:data];
        //NSLog(@"Serialized %d bytes - MsgId of value %d", data.length, [msgId intValue]);
    } else if (msecsSinceMidnight) {
        int identifier = CFSwapInt32HostToBig(15);
        [data appendBytes:(char*)&identifier length:4];
        [data appendBytes:"\x00" length:1];
        int i = CFSwapInt32HostToBig([msecsSinceMidnight intValue]);
        [data appendBytes:(char*)&i length:4];
    } else {
        NSLog(@"ERROR: Dont know how to serialize %@", self);
    }
    return data;
}

- (void) serialize:(const char*)c into:(NSMutableData*)data
{
    int len = CFSwapInt32HostToBig(strlen(c));
    [data appendBytes:(char*)&len length:4];
    [data appendBytes:c length:strlen(c)];
}

- (NSString *)description
{
    NSMutableString *myDescription = [NSMutableString string];
    if (dict) {
        myDescription = [NSMutableString string];
        [myDescription appendString:@"QVariant(dictionary("];
        [myDescription appendString:[dict description]];
        [myDescription appendString:@"))"];
    }    
    else if (string)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(string(%@))", string];
    else if (boolean)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(boolean(%@))", boolean];
    else if (integer)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(integer(%@))", integer];
    else if (list)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(list(%@))", list];
    else if (byteArray) 
        myDescription = [NSMutableString stringWithFormat:@"QVariant(byteArray(%d))", byteArray.length];
    else if (message)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(%@)", message];
    else if (bufferInfo)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(%@)", bufferInfo];
    else if (networkId)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(%@)", networkId];
    else if (identityId)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(%@)", identityId];
    else if (bufferId)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(%@)", bufferId];
    else if (msgId)
        myDescription = [NSMutableString stringWithFormat:@"QVariant(%@)", msgId];
    else
        [myDescription appendString:@"FIXME!"];
    return myDescription;
}

- (int) intValue
{
    return [integer intValue];
}

- (NSString*)asStringFromStringOrByteArray
{
    if (string)
        return string;
    if (byteArray) {
        NSString *ret = [[NSString alloc]         initWithBytes:byteArray.bytes
                                                length:byteArray.length   
                                            encoding:NSUTF8StringEncoding];
        return ret;

    }
    
    return @"";
}


@end
