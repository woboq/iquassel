// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <UIKit/UIKit.h>
#import "QuasselCoreConnectionDelegate.h"
#import "SignedId.h"
#import "GCDAsyncSocket.h"
#import "IrcUser.h"

@interface QuasselCoreConnection : NSObject 
{
    enum State {
        Connecting,
        SentClientInit,
        SentClientLogin,
        ReceivedClientLoginAck,
        ReceivedSessionInit
    };
    
    // Copied from signalproxy.h
    enum RequestType {
        Sync = 1,
        RpcCall,
        InitRequest,
        InitData,
        HeartBeat,
        HeartBeatReply
    };

    dispatch_queue_t queue;
}
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *passWord;
@property (nonatomic, strong) NSString *hostName;
@property (nonatomic) int port;

@property (nonatomic, strong) NSMutableArray *neworkIdList;
@property (nonatomic, strong) NSMutableDictionary *networkIdNetworkNameMap;
@property (nonatomic, strong) NSMutableDictionary *networkIdMyNickMap;
@property (nonatomic, strong) NSMutableDictionary *bufferIdBufferInfoMap;
@property (nonatomic, strong) NSMutableDictionary *networkIdBufferIdListMap;
@property (nonatomic, strong) NSMutableDictionary *networkIdServerBufferInfoMap;
@property (nonatomic, strong) NSMutableDictionary *bufferIdMessageListMap;
@property (nonatomic, strong) NSMutableArray *visibleBufferIdsList;
@property (nonatomic, strong) NSMutableSet *backlogRequestedForAlreadyBufferIdSet;
@property (nonatomic, strong) NSMutableDictionary *bufferIdLastSeenMessageIdMap;
@property (nonatomic, strong) NSMutableDictionary *bufferIdBufferActivityMap;
@property (nonatomic, strong) NSMutableDictionary *networkIdUserMapMap; // NetworkId -> NSDictionary(Nick -> IrcUser)
@property (nonatomic, strong) NSMutableDictionary *networkIdChannelMapMap; // NetworkId -> NSDictionary(Channel -> IrcChannel)
- (IrcUser*) ircUserForNetworkId:(NetworkId*)networkId andNick:(NSString*)nick;
- (NSArray*) ircUsersForChannelWithBufferId:(BufferId*)bufferId;

@property (nonatomic) int networkInitsReceived;
@property (nonatomic, strong) NSString *bufferViewConfigId;

@property (nonatomic) enum State state;

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSMutableData *inputData;
@property (nonatomic) long inputDataCounter;


@property (nonatomic) BOOL serverSupportsCompression;
@property (nonatomic) BOOL compressed;
@property (nonatomic) long uncompressedInputDataCounter;

@property (nonatomic, strong) NSString *lastErrorMsg;


@property (nonatomic, strong) id<QuasselCoreConnectionDelegate> delegate;


- (void) connectTo:(NSString*)hostName port:(int)port userName:(NSString*)userName passWord:(NSString*)passWord;
@property (nonatomic, strong) BufferId *bufferIdToRestore;
- (void) disconnect;

- (void) fetchMoreBacklog:(BufferId*)bufferId;
- (void) fetchSomeBacklog:(BufferId*)bufferId  amount:(int)amount;
- (void) fetchSomeBacklog:(BufferId*)bufferId;

- (void) setLastSeenMsg:(MsgId*)m forBuffer:(BufferId*)bufferId;
- (MsgId*) lastSeenMsgForBuffer:(BufferId*)bufferId;

- (enum BufferActivity) bufferActivityForBuffer:(BufferId*)bufferId;
- (void) computeBufferActivityForBuffer:(BufferId*)bufferId;

- (int) computeUnreadCountForBuffer:(BufferId*)bufferId;
- (int) computeUnreadCountForAllBuffers;
- (int) computeRelevantUnreadCount;

- (void) sendMessage:(NSString*)msg toBuffer:(BufferId*)bufferId;
- (void) openQueryBufferForUser:(IrcUser*)user onNetwork:(NetworkId*)networkId;


@end
