// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"


#import <Foundation/Foundation.h>

@class BufferId;
@class NetworkId;

@interface BufferInfo : NSObject
{
    enum BufferType {
        InvalidBuffer = 0x00,
        StatusBuffer = 0x01,
        ChannelBuffer = 0x02,
        QueryBuffer = 0x04,
        GroupBuffer = 0x08
    };
    
    enum BufferActivity {
        BufferActivityNoActivity = 0x00,
        BufferActivityOtherActivity = 0x01,
        BufferActivityNewMessage = 0x02,
        BufferActivityHighlight = 0x40
    };
    
    NSString *bufferName;
    
    BufferId *bufferId;
    NetworkId *networkId;
    enum BufferType bufferType;
    unsigned int groupId;
    
    //enum Buff
}

@property (strong, nonatomic) NSString *bufferName;
@property (strong, nonatomic) BufferId *bufferId;
@property (strong, nonatomic) NetworkId *networkId;
@property (nonatomic) enum BufferType bufferType;
@property (nonatomic) unsigned int groupId;

@property (nonatomic) enum BufferActivity bufferActivity;

- (id) initWithSerialization:(NSData*)s bytesRead:(int*)bytesRead;

- (void) serialize:(NSMutableData*)data;

@end
