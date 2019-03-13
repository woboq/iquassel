// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>

@class Message;
@class MsgId;
@class BufferId;
@class NetworkId;

@protocol QuasselCoreConnectionDelegate <NSObject>

- (void) quasselSocketFailedConnect:(NSString*)msg;
- (void) quasselConnected;
- (void) quasselEncrypted;
- (void) quasselAuthenticated;
- (void) quasselBufferListReceived;
- (void) quasselNetworkInitReceived:(NSString*)networkName;
- (void) quasselAllNetworkInitReceived;
- (void) quasselBufferListUpdated;
- (void) quasselSocketDidDisconnect:(NSString*)msg;

- (void) quasselSwitchToBuffer:(BufferId*)bufferId;

enum ReceiveStyle { ReceiveStyleAppended, ReceiveStylePrepended, ReceiveStyleBacklog };
- (void) quasselMessageReceived:(Message*)msg received:(enum ReceiveStyle)style onIndex:(int)i;
- (void) quasselMessagesReceived:(NSArray*)messages received:(enum ReceiveStyle)style;

- (void) quasselLastSeenMsgUpdated:(MsgId*)messageId forBuffer:(BufferId*)bufferId;

- (void) quasselNetworkNameUpdated:(NetworkId*)networkId;
@end
