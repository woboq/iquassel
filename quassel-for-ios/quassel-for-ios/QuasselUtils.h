// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>
#import "Message.h"


@interface QuasselUtils : NSObject

+ (NSString*) extractNick:(NSString*)nickUserHost;
+ (NSString*) extractTimestamp:(Message*)message;

+ (NSString*)transformedByteValue:(long)value;

+ (NSData*) qUncompress:(const char*) data count:(int)count;
+ (NSData*) qCompress:(const char*)data count:(int)nbytes;

+ (NSString*) trimStringForConsole:(NSString*)string;

+ (UIColor*) uiColorFromNick:(NSString*)nick;

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@end
