// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"


#import "QuasselUtils.h"
#include <zlib.h>

@implementation QuasselUtils

+ (NSString*) extractNick:(NSString*)nickUserHost
{
    NSRange r = [nickUserHost rangeOfString:@"!"];
    if (r.location == NSNotFound)
        return nickUserHost;
    return [nickUserHost substringToIndex:r.location];
}

+ (NSString*) extractTimestamp:(Message*)message
{
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"[HH:mm]"];
    return [timeFormat stringFromDate:message.messageDate];
}

+ (NSString*)transformedByteValue:(long)value
{
    double convertedValue = value;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KB",@"MB",@"GB",@"TB",@"PB",@"EB",@"ZB",@"YB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor],value];
}

+ (NSData*) qCompress:(const char*)data count:(int)nbytes
{
    unsigned long len = nbytes + nbytes / 100 + 13;
    NSMutableData* bazip = [[NSMutableData alloc] init];
    int res;
    do {
        [bazip setLength:(len + 4)];
        
        res = compress2([bazip mutableBytes]+4, &len, (const unsigned char*)data, nbytes, Z_DEFAULT_COMPRESSION);        
        switch (res) {
            case Z_OK:
                [bazip setLength:(len + 4)];
                
                char *mutableBytes = [bazip mutableBytes];
                mutableBytes[0] = (nbytes & 0xff000000) >> 24;
                mutableBytes[1] = (nbytes & 0x00ff0000) >> 16;
                mutableBytes[2] = (nbytes & 0x0000ff00) >> 8;
                mutableBytes[3] = (nbytes & 0x000000ff);
                break;
            case Z_MEM_ERROR:
                NSLog(@"qCompress: Z_MEM_ERROR: Not enough memory");
                [bazip setLength:(0)];
                break;
            case Z_BUF_ERROR:
                NSLog(@"qCompress: len %lu not enough, adjusting to %lu", len, 2*len);
                len *= 2;
                break;
        }
    } while (res == Z_BUF_ERROR);
    return bazip;
}


+ (NSData*) qUncompress:(const char*) data count:(int)count
{
    unsigned int expectedSize = CFSwapInt32BigToHost(*(unsigned int*)data); //(data[0] << 24) | (data[1] << 16) |  (data[2] <<  8) | (data[3]      );
    unsigned long len = MAX(expectedSize, 1ul);
    NSMutableData *baunzip = [NSMutableData dataWithLength:len];
    int res = uncompress((unsigned char*)[baunzip mutableBytes], &len, (unsigned char*)data+4, count-4);
            
    if (res != Z_OK) {
        NSLog(@"Decompression error? expectedSize=%d", expectedSize);
        baunzip = [NSMutableData data];
    }
    
    return baunzip;
}

+ (NSString*) trimStringForConsole:(NSString*)string
{
    if (string.length > 8*1024)
        string = [string substringToIndex:8*1024]; 
    return string;
}

static const unsigned int crc_tbl[16] = {
    	    0x0000, 0x1081, 0x2102, 0x3183,
    	    0x4204, 0x5285, 0x6306, 0x7387,
    	    0x8408, 0x9489, 0xa50a, 0xb58b,
    	    0xc60c, 0xd68d, 0xe70e, 0xf78f
};
unsigned int qChecksum(const char *data , unsigned int len)
{
    unsigned int crc = 0xffff;
    unsigned char c;
    const  unsigned char *p = (const unsigned char *)(data);
    while (len--) {
	        c = *p++;
	        crc = ((crc >> 4) & 0x0fff) ^ crc_tbl[((crc ^ c) & 15)];
	        c >>= 4;
	        crc = ((crc >> 4) & 0x0fff) ^ crc_tbl[((crc ^ c) & 15)];
	    }
    return ~crc & 0xffff;
}

// from settings.qss
+ (UIColor*) uiColorFromNick:(NSString*)nick
{
    nick = [[QuasselUtils extractNick:nick] lowercaseString];
    if (!nick || nick.length == 0) {
        return UIColorFromRGB(0x000000);
    }
    // remove _ at end
    while (nick.length > 0 && [nick characterAtIndex:nick.length-1] == '_')
        nick = [nick substringToIndex:[nick length] - 1];
    
    NSData *rawNick = [nick dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    int16_t hash = qChecksum(rawNick.bytes, rawNick.length);
    hash = (hash & 0xf)/* + 1*/;
    if (hash == 0x00)
        return UIColorFromRGB(0xe90d7f);
    else if (hash == 0x01)
        return UIColorFromRGB(0x8e55e9);
    else if (hash == 0x02)
        return UIColorFromRGB(0xb30e0e);
    else if (hash == 0x03)
        return UIColorFromRGB(0x17b339);
    else if (hash == 0x04)
        return UIColorFromRGB(0x58afb3);
    else if (hash == 0x05)
        return UIColorFromRGB(0x9d54b3);
    else if (hash == 0x06)
        return UIColorFromRGB(0xb39775);
    else if (hash == 0x07)
        return UIColorFromRGB(0x3176b3);
    else if (hash == 0x08)
        return UIColorFromRGB(0xe90d7f);
    else if (hash == 0x09)
        return UIColorFromRGB(0x8e55e9);
    else if (hash == 0x0a)
        return UIColorFromRGB(0xb30e0e);
    else if (hash == 0x0b)
        return UIColorFromRGB(0x17b339);
    else if (hash == 0x0c)
        return UIColorFromRGB(0x58afb3);
    else if (hash == 0x0d)
        return UIColorFromRGB(0x9d54b3);
    else if (hash == 0x0e)
        return UIColorFromRGB(0xb39775);
    else if (hash == 0x0f)
        return UIColorFromRGB(0x3176b3);
    else
        return UIColorFromRGB(0x000000);
}


@end
