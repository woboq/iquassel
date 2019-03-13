// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>
#import "SignedId.h"
#import "BufferInfo.h"

@interface Message : NSObject
{
    enum MessageType {
		MessageTypePlain = 0x00001,
		MessageTypeNotice = 0x00002,
		MessageTypeAction = 0x00004,
		MessageTypeNick = 0x00008,
		MessageTypeMode = 0x00010,
		MessageTypeJoin = 0x00020,
		MessageTypePart = 0x00040,
		MessageTypeQuit = 0x00080,
		MessageTypeKick = 0x00100,
		MessageTypeKill = 0x00200,
		MessageTypeServer = 0x00400,
		MessageTypeInfo = 0x00800,
		MessageTypeError = 0x01000,
		MessageTypeDayChange = 0x02000,
		MessageTypeTopic = 0x04000,
		MessageTypeNetsplitJoin = 0x08000,
		MessageTypeNetsplitQuit = 0x10000,
		MessageTypeInvite = 0x20000
    };
    
    enum MessageFlag {
		MessageFlagNone = 0x00,
		MessageFlagSelf = 0x01,
		MessageFlagHilight = 0x02,
		MessageFlagRedirected = 0x04,
		MessageFlagServerMsg = 0x08,
		MessageFlagBacklog = 0x80
    };
    
    NSDate *messageDate;
    enum MessageType messageType;
    enum MessageFlag messageFlag;
    BufferInfo *bufferInfo;
    MsgId* messageId;
    NSString *sender;
    NSString *contents;
    
}

@property (nonatomic, strong) NSDate *messageDate;
@property (nonatomic)  enum MessageType messageType;
@property (nonatomic)  enum MessageFlag messageFlag;
@property (nonatomic, strong)  BufferInfo *bufferInfo;
@property (nonatomic, strong)  MsgId* messageId;
@property (nonatomic, strong)  NSString *sender;
@property (nonatomic, strong)  NSString *contents;


- (id) initWithSerialization:(NSData*)s bytesRead:(int*)bytesRead;


@end
