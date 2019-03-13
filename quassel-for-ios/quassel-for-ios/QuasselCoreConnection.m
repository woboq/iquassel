// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "QuasselCoreConnection.h"
#import "QVariant.h"
#import "QBoolean.h"
#import "BufferInfo.h"
#import "Message.h"
#import "QuasselCoreConnectionDelegate.h"
#import "SignedId.h"
#import "QuasselUtils.h"
#import "IrcUser.h"
#import "IrcChannel.h"
#import "AppDelegate.h"


@implementation QuasselCoreConnection

@synthesize userName;
@synthesize passWord;
@synthesize hostName;
@synthesize port;

@synthesize socket;
@synthesize inputData;
@synthesize inputDataCounter;

@synthesize serverSupportsCompression;
@synthesize compressed;
@synthesize uncompressedInputDataCounter;

@synthesize lastErrorMsg;
@synthesize state;
@synthesize bufferIdBufferInfoMap;
@synthesize networkIdBufferIdListMap;
@synthesize neworkIdList;
@synthesize networkIdNetworkNameMap;
@synthesize bufferIdMessageListMap;
@synthesize delegate;
@synthesize networkIdServerBufferInfoMap;
@synthesize visibleBufferIdsList;
@synthesize backlogRequestedForAlreadyBufferIdSet;
@synthesize bufferIdLastSeenMessageIdMap;
@synthesize bufferIdBufferActivityMap;
@synthesize networkIdUserMapMap;
@synthesize networkIdChannelMapMap;
@synthesize networkInitsReceived;

@synthesize bufferIdToRestore;


- (id) init {
    NSLog(@"QuasselCoreConnection init");

    self = [super init];
    queue = dispatch_queue_create("QuasselCoreConnection", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void) connectTo:(NSString*)h port:(int)p userName:(NSString*)un passWord:(NSString*)pw
{
    NSLog(@"QuasselCoreConnection connect");

    self.hostName = h;
    self.port = p;
    self.userName = un;
    self.passWord = pw;


    [self reConnect];
}

- (void) reConnect {
    NSLog(@"QuasselCoreConnection reConnect");

    state = Connecting;
    bufferIdBufferInfoMap = nil;
    networkIdBufferIdListMap = nil;
    neworkIdList = nil;
    bufferIdMessageListMap = nil;
    networkIdServerBufferInfoMap = nil;
    visibleBufferIdsList = nil;
    backlogRequestedForAlreadyBufferIdSet = nil;
    bufferIdLastSeenMessageIdMap = nil;
    bufferIdBufferActivityMap = nil;

    networkIdNetworkNameMap = nil;

    networkIdUserMapMap = nil;;
    networkInitsReceived = 0;
    networkIdChannelMapMap = nil;

    inputDataCounter = 0;
    serverSupportsCompression = NO;
    compressed = NO;


    NSLog(@"Connecting to %@:%d", hostName, port);
    socket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                        delegateQueue:queue
                                          socketQueue:queue];


    //[socket connectToHost:@"noreg.fauleban.de" onPort:4243 error:nil];
    NSError *e = nil;
    [socket connectToHost:hostName onPort:port  withTimeout:10 error:&e];
    if (e) {
        NSLog(@"Error connectToHost %@", e.localizedDescription);
        lastErrorMsg = e.localizedDescription;
        [delegate quasselSocketFailedConnect:e.localizedDescription];
    }
}

- (void) disconnect
{
    NSLog(@"disconnect");
    if (socket.isConnected) {
        self.lastErrorMsg = @"Please reconnect to core";
        [socket disconnect];
        //[delegate quasselSocketDidDisconnect:@"timeout"];
    }
}

- (void) fetchMoreBacklog:(BufferId*)bufferId
{
    NSLog(@"Fetching MORE backlog for %@", [[bufferIdBufferInfoMap objectForKey:bufferId] bufferName]);
    if ([[bufferIdMessageListMap objectForKey:bufferId] count] == 0) {
        [self fetchSomeBacklog:bufferId];
        return;
    }


    NSMutableArray *commandArray = [NSMutableArray array];
    [commandArray addObject:[[QVariant alloc] initWithInt:Sync]];
    [commandArray addObject:[[QVariant alloc] initWithString:@"BacklogManager"]];
    [commandArray addObject:[[QVariant alloc] initWithString:@""]];
    [commandArray addObject:[[QVariant alloc] initWithString:@"requestBacklog"]];
    [commandArray addObject:[[QVariant alloc] initWithBufferId:bufferId]];

    NSLog(@"Message count for buffer %@ is %lu", bufferId, (unsigned long)[[bufferIdMessageListMap objectForKey:bufferId] count]);
    [commandArray addObject:[[QVariant alloc] initWithMsgId:[[MsgId alloc] initWithInt:-1]]]; //"first"
    [commandArray addObject:[[QVariant alloc] initWithMsgId:[[[bufferIdMessageListMap objectForKey:bufferId] objectAtIndex:0] messageId]]]; // "fast"

    [commandArray addObject:[[QVariant alloc] initWithInt:30]]; // max amount
    [commandArray addObject:[[QVariant alloc] initWithInt:0]]; // additional.. whatever tha means.
    [self sendCommand:commandArray];
}

- (void) fetchSomeBacklog:(BufferId*)bufferId amount:(int)amount
{
    NSLog(@"Fetching some backlog for %@", [[bufferIdBufferInfoMap objectForKey:bufferId] bufferName]);

    [backlogRequestedForAlreadyBufferIdSet addObject:bufferId];

    NSMutableArray *commandArray = [NSMutableArray array];
    [commandArray addObject:[[QVariant alloc] initWithInt:Sync]];
    [commandArray addObject:[[QVariant alloc] initWithString:@"BacklogManager"]];
    [commandArray addObject:[[QVariant alloc] initWithString:@""]];
    [commandArray addObject:[[QVariant alloc] initWithString:@"requestBacklog"]];
    [commandArray addObject:[[QVariant alloc] initWithBufferId:bufferId]];

    NSLog(@"Message count for buffer %@ is %lu", bufferId, (unsigned long)[[bufferIdMessageListMap objectForKey:bufferId] count]);
    // This code did some fancy things based on the last seen message, but I think it is for now better to just fetch the last messages
    [commandArray addObject:[[QVariant alloc] initWithMsgId:[[MsgId alloc] initWithInt:-1]]]; //"first"
    [commandArray addObject:[[QVariant alloc] initWithMsgId:[[MsgId alloc] initWithInt:-1]]]; // "fast"

    [commandArray addObject:[[QVariant alloc] initWithInt:amount]]; // max amount
    [commandArray addObject:[[QVariant alloc] initWithInt:0]]; // additional.. whatever tha means.
    [self sendCommand:commandArray];
}

- (void) fetchSomeBacklog:(BufferId*)bufferId
{
    [self fetchSomeBacklog:bufferId amount:30];
}


- (void) handleReceivedNetworkInit:(NSArray*)networkInit
{
    /*
     2014-01-08 15:37:46.114 quassel-for-ios[14002:70b] isConnected => QVariant(boolean(YES))

     2014-01-08 15:37:46.114 quassel-for-ios[14002:70b] myNick => QVariant(string(guruz))




     012-09-14 13:33:47.984 quassel-for-ios[8471:707] ...list (
     "QVariant(integer(4))",
     "QVariant(byteArray(7))",
     "QVariant(string(7))",
     "QVariant(dictionary({\n    IrcUsersAndChannels = \"QVariant(dictionary({\\n    channels = \\\"QVariant(dictionary({\\\\n    \\\\\\\"#changelog\\\\\\\" = \\\\\\\"QVariant(dictionary({\\\\\\\\n    ChanModes = \\\\\\\\\\\\\\\"QVariant(dictionary({\\\\\\\\\\\\\\\\n    A = \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"QVariant(dictionary({\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n}))\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\";\\\\\\\\\\\\\\\\n    B = \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"QVariant(dictionary({\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n}))\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\";\\\\\\\\\\\\\\\\n    C = \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"QVariant(dictionary({\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n}))\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\";\\\\\\\\\\\\\\\\n    D = \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"QVariant(string(mnrt))\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\";\\\\\\\\\\\\\\\\n}))\\\\\\\\\\\\\\\";\\\\\\\\n    UserModes = \\\\\\\\\\\\\\\"QVariant(dictionary({\\\\\\\\\\\\\\\\n    Aaaron = \\\\\\

     channel hat ChanModes, UserModes, name, topic

     users hat key guruz!mgoetz@i.love.debian.org, values channels, away, idleTime, nick, realName, user
     users = "QVariant(dictionary({\n    \"guruz!mgoetz@i.love.debian.org\" = \"QVariant(dictionary({\\n    away = \\\"QVariant(boolean(NO))\\\";\\n    awayMessage = \\\"QVariant(string())\\\";\\n    channels = \\\"QVariant(list((\\\\n    \\\\\\\"#woboq\\\\\\\",\\\\n    \\\\\\\"#teamdrive\\\\\\\"\\\\n)))\\\";\\n    host = \\\"QVariant(string(i.love.debian.org))\\\";\\n    idleTime = \\\"FIXME!\\\";\\n    ircOperator = \\\"QVariant(string())\\\";\\n    lastAwayMessage = \\\"QVariant(integer(0))\\\";\\n    loginTime = \\\"FIXME!\\\";\\n    nick = \\\"QVariant(string(guruz))\\\";\\n    realName = \\\"QVariant(string(Markus Goetz))\\\";\\n    server = \\\"QVariant(string(hybrid7.debian.local))\\\";\\n    suserHost = \\\"QVariant(string())\\\";\\n    user = \\\"QVariant(string(mgoetz))\\\";\\n    userModes = \\\"QVariant(string())\\\";\\n    whoisServiceReply = \\\"QVariant(string())\\\";\\n}))\";\n

     der IrcChannel hat auch nochmal ein dictionary users das redundant das gleiche speichert?

     */
    NetworkId *networkId = [[NetworkId alloc] initWithInt:[[[networkInit objectAtIndex:2] string] intValue]];
    NSLog(@"Received NetworkInit Data for %d", networkId.intValue);
    NSDictionary *initDict = [[networkInit objectAtIndex:3] dict];
#ifdef QUASSEL_DEBUG_PROTOCOL
    [initDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSLog(@"%@ => %@", key, [QuasselUtils trimStringForConsole:[obj description]]);
    }];
#endif

    // key networkName networkName => QVariant(string(QuakeNet))
    NSString *networkName = [[initDict objectForKey:@"networkName"] string];
    [networkIdNetworkNameMap setObject:networkName forKey:networkId];
    [delegate quasselNetworkNameUpdated:networkId];


    NSDictionary *ircUsersAndChannels = [[initDict objectForKey:@"IrcUsersAndChannels"] dict];
    NSDictionary *channels = [[ircUsersAndChannels objectForKey:@"channels"] dict];
    NSDictionary *users = [[ircUsersAndChannels objectForKey:@"users"] dict];

    NSMutableDictionary *usersForNetwork = [self.networkIdUserMapMap objectForKey:networkId];
    NSMutableDictionary *channelsForNetwork = [self.networkIdChannelMapMap objectForKey:networkId];
    for (NSString *channel in channels) {
        //NSLog(@"CHANNEL %@", channel);
        IrcChannel *ircChannel = [[IrcChannel alloc] initWithName:channel];
        // FIXME set topic etc

        // add channel to map
        [channelsForNetwork setObject:ircChannel forKey:channel];
    }

    for (NSString *uhost in users) {
        NSDictionary *value = [[users objectForKey:uhost] dict];
        IrcUser *user = [[IrcUser alloc] initWithUhost:uhost];
        NSArray *channelsOfUser = [[value valueForKey:@"channels"] list];
        //NSLog(@"USER %@ CHANNELS %@", user.nick, channelsOfUser);
        [usersForNetwork setValue:user forKey:user.nick];

        // add user to each channel he is in
        for (NSString *channelOfUser in channelsOfUser) {
            [[channelsForNetwork valueForKey:channelOfUser] addUser:user];
        }

    }

    for (IrcChannel *ircChannel in channelsForNetwork.allValues) {
        //NSLog(@"[channel] %@", [ircChannel description]);
    }


//    networkInitsReceived++;
//    if (networkInitsReceived == neworkIdList.count ) {
//        [delegate quasselAllNetworkInitReceived];
//    } else {
//        [delegate quasselNetworkInitReceived:networkName];
//    }
}


- (void) sendQVariant:(QVariant*) qvariant
{
    if (!socket || !socket.isConnected) {
        NSLog(@"sendQVariant: Error: No socket object or socket not connected: %@", socket);
        return;
    }
    // 1. serialize 'data' to something (this is QVariant/QDataStream encoding)
    //NSLog(@"Serializing %@", qvariant);
    NSData *serializedQVariant = [qvariant serialize];

    if (compressed) {
        NSData *compressedData = [QuasselUtils qCompress:serializedQVariant.bytes count:serializedQVariant.length];
        //NSLog(@"...and decompressed again to %d bytes",  [QuasselUtils qUncompress:compressedData.bytes count:compressedData.length].length);
        // serialize as byte array

        NSLog(@"sendQVariant: Will send %lu bytes (uncompressed: %lu bytes)", (unsigned long)compressedData.length, (unsigned long)serializedQVariant.length);

        // Compressed data als qbytearrayraushauen!

        int length = CFSwapInt32HostToBig(compressedData.length+4);
        NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(length)];
        int compressedLength = CFSwapInt32HostToBig(compressedData.length);
        NSData *compressedLengthData = [NSData dataWithBytes:(char*)&compressedLength length:4];

        NSMutableData *whole = [NSMutableData dataWithData:lengthData];
        [whole appendData:compressedLengthData];
        [whole appendData:compressedData];

        [socket writeData:whole withTimeout:-1 tag:-1];
    } else {
        //data = serializedQVariant;
        // 2. Send the size of something as UInt (this is quassel-protocol)
        int length = CFSwapInt32HostToBig(serializedQVariant.length);
        NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(length)];

        NSMutableData *whole = [NSMutableData dataWithData:lengthData];
        [whole appendData:serializedQVariant];
        [socket writeData:whole withTimeout:-1 tag:-1];

        //NSLog(@"sendQVariant: Sent %lu bytes", serializedQVariant.length+4);
    }

    [socket readDataWithTimeout:-1 tag:-1];
}


- (void) sendQVariantMap:(NSDictionary*)map
{
    // FIXME
    // QVariant<Map<String, QVariant<?>>> bufstruct = new QVariant<Map<String, QVariant<?>>>(data, QVariantType.Map);
    QVariant *qvariantMapInsideQVariant = [[QVariant alloc] initWithQVariantMap:map];
    [self sendQVariant:qvariantMapInsideQVariant];
}

- (void) sendCommand:(NSArray*)cmd
{
    QVariant *qvariantListInsideQVariant = [[QVariant alloc] initWithQVariantList:cmd];
    [self sendQVariant:qvariantListInsideQVariant];
}


- (void) sendClientLogin {
    NSLog(@"Logging in user %@", userName);
    NSDictionary *initial = [NSMutableDictionary dictionaryWithCapacity:7];
    [initial setValue:[[QVariant alloc] initWithString:@"ClientLogin"] forKey:@"MsgType"];
    [initial setValue:[[QVariant alloc] initWithString:userName] forKey:@"User"];
    [initial setValue:[[QVariant alloc] initWithString:passWord] forKey:@"Password"];


    [self sendQVariantMap:initial];


    // FIXME: We could call fetchSomeBacklog here if we'd remember if the server
    // supports and expects compression?
    // No, this didnt work, the server just closed on us.

    state = SentClientLogin;
}


- (void) handleReceivedVariant:(QVariant*)v
{
    if (v.dict)
        NSLog(@"[handleReceivedVariant] %@", [[v.dict valueForKey:@"MsgType"] string]);
    else
        NSLog(@"[handleReceivedVariant] list");

    if (state == SentClientInit) {
        if (v.dict) {
            NSString *msgType = [[v.dict valueForKey:@"MsgType"] string];
            if ([msgType isEqualToString:@"ClientInitAck"]) {
                NSLog(@"Connected to %@", [[v.dict valueForKey:@"CoreInfo"] string]);

#ifdef QUASSEL_DEBUG_PROTOCOL
                NSLog(@"   => %@", v.dict);
#endif

                serverSupportsCompression = [[[v.dict valueForKey:@"SupportsCompression"] boolean] value];
                // FIXME: As an optimization, when reconnecting we could already have the
                // startTLS queued up when sending the ClientInit?
                BOOL supportsSsl = [[[v.dict valueForKey:@"SupportSsl"] boolean] value];
                if (supportsSsl) {
                    NSLog(@"Starting TLS");
                    [socket performBlock:^{
                        NSLog(@"calling startTLS");
                        NSDictionary *sslDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 (id)kCFBooleanFalse, (id)kCFStreamSSLValidatesCertificateChain,
                                                 nil];
                        [socket startTLS:sslDict];
                        NSLog(@"%@ %@", socket.debugDescription, socket.description);
                    }];


                } else {
                    NSLog(@"Warning: TLS not supported by core");
                    [self sendClientLogin];
                }

            }
        }
    } else if (state == SentClientLogin) {
        if (v.dict) {
            NSString *msgType = [[v.dict valueForKey:@"MsgType"] string];
            //NSLog(@"Received %@", msgType);
            if ([msgType isEqualToString:@"ClientLoginAck"]) {
                state = ReceivedClientLoginAck;
                [delegate quasselAuthenticated];
            } else {
                // login failed
                NSLog(@"Login failed!");
                socket.delegate = nil;
                socket = nil;
                lastErrorMsg = @"Wrong username or password";
                [delegate quasselSocketDidDisconnect:self.lastErrorMsg];
            }
        }
    } else if (state == ReceivedClientLoginAck) {

        //                // START SESSION INIT
        //                updateInitProgress("Receiving session state...");
        //                reply = readQVariantMap();
        //                /*System.out.println("SESSION INIT: ");
        //                 for (String key : reply.keySet()) {
        //                 System.out.println("\t" + key + " : " + reply.get(key));
        //                 }*/
        //
        //                Map<String, QVariant<?>> sessionState = (Map<String, QVariant<?>>) reply.get("SessionState").getData();
        if (v.dict) {
            NSString *msgType = [[v.dict valueForKey:@"MsgType"] string];
            if ([msgType isEqualToString:@"SessionInit"]) {
                // FIXME Tried to do fetchSomeBacklog here, but the server
                // just ignored it.


                //NSLog(@"Receiving session state...");
                NSDictionary *sessionState = [[v.dict valueForKey:@"SessionState"] dict];
                //NSLog (@"sessionstate = %@", sessionState);

                // Fuer jede network ID dann was im model anlegen
                QVariant *networkIds = [sessionState valueForKey:@"NetworkIds"];
                //NSLog(@"networkIds = %@", networkIds);
                neworkIdList = [[NSMutableArray alloc] initWithCapacity:networkIds.list.count];
                networkIdNetworkNameMap = [NSMutableDictionary dictionaryWithCapacity:networkIds.list.count];
                networkIdUserMapMap = [NSMutableDictionary dictionaryWithCapacity:neworkIdList.count];
                networkIdChannelMapMap = [NSMutableDictionary dictionaryWithCapacity:neworkIdList.count];
                [networkIds.list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [neworkIdList addObject:[obj networkId]];
                    [networkIdUserMapMap setObject:[NSMutableDictionary dictionary] forKey:[obj networkId]];
                    [networkIdChannelMapMap setObject:[NSMutableDictionary dictionary] forKey:[obj networkId]];
                }];


                // Dann alle buffer adden
                QVariant *bufferInfos = [sessionState valueForKey:@"BufferInfos"];
                networkIdBufferIdListMap = [NSMutableDictionary dictionaryWithCapacity:neworkIdList.count];
                networkIdServerBufferInfoMap = [NSMutableDictionary dictionaryWithCapacity:neworkIdList.count];
                bufferIdMessageListMap  = [NSMutableDictionary dictionaryWithCapacity:bufferInfos.list.count];
                bufferIdBufferInfoMap  = [NSMutableDictionary dictionaryWithCapacity:bufferInfos.list.count];
                bufferIdBufferActivityMap = [NSMutableDictionary dictionaryWithCapacity:bufferInfos.list.count];

                //NSLog(@"bufferInfos = %@", bufferInfos);
                [bufferInfos.list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    BufferInfo *bI = [obj bufferInfo];
                    [bufferIdMessageListMap setObject:[NSMutableArray array] forKey:bI.bufferId];
                    [bufferIdBufferInfoMap setObject:bI forKey:bI.bufferId];
                    if (bI.bufferType == StatusBuffer)
                        [networkIdServerBufferInfoMap setObject:bI forKey:[bI networkId]];

                }];
                //NSLog(@"networkIdBufferInfoMap = %@", networkIdBufferInfoListMap);
                visibleBufferIdsList = [NSMutableArray arrayWithCapacity:bufferIdMessageListMap.count];
                backlogRequestedForAlreadyBufferIdSet = [NSMutableSet setWithCapacity:bufferIdMessageListMap.count];

                state = ReceivedSessionInit;
                compressed = serverSupportsCompression;


                // Fetching some backlog here early for the last remembered buffer
                // saves us some time which allows us to show the backlog earlier to user
                if (self.bufferIdToRestore && self.bufferIdToRestore.intValue > 0) {
                    NSLog(@"Early backlog fetch");
                    [backlogRequestedForAlreadyBufferIdSet addObject:self.bufferIdToRestore];
                    [self fetchSomeBacklog:self.bufferIdToRestore amount:45];
                } else {
                    // No buffer to restore
                }
                // FIXME: In a future version we could already change the UI
                // now to display the received backlog even earlier

                NSLog(@"Sending BufferSyncer InitRequest");

                [self sendCommand:[NSArray arrayWithObjects:[[QVariant alloc] initWithInt:InitRequest],
                                   [[QVariant alloc] initWithString:@"BufferSyncer"],
                                   [[QVariant alloc] initWithString:@""],
                                   nil
                                   ]];
                NSLog(@"Sending BufferViewConfig InitRequest");
                [self sendCommand:[NSArray arrayWithObjects:[[QVariant alloc] initWithInt:InitRequest],
                                   [[QVariant alloc] initWithString:@"BufferViewConfig"],
                                   [[QVariant alloc] initWithString:@"0"],
                                   nil
                                   ]];

                //[delegate quasselAllNetworkInitReceived];
                return;

                // Now done after we received the BufferViewConfig
//                [neworkIdList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//                    [self sendCommand:[NSArray arrayWithObjects:[[QVariant alloc] initWithInt:InitRequest],
//                                       [[QVariant alloc] initWithString:@"Network"],
//                                       [[QVariant alloc] initWithString:[NSString stringWithFormat:@"%d",[obj intValue]]],
//                                       nil
//                                       ]];
//                }];




            }

        }
    } else if (state == ReceivedSessionInit) {
        if (v.dict) {
            NSLog(@"...map FIXME");
        } else if (v.list) {
            //NSLog(@"...list %@[...]", [QuasselUtils trimStringForConsole:v.list.description]);
            //NSLog(@"...list");

            int requestType = [[v.list objectAtIndex:0] intValue];
            if (requestType == Sync) { // 1
                //NSLog(@"...Sync");
                /*
                 2012-07-18 14:29:47.240 quassel-for-ios[42671:707] ...list (
                 "<QVariant: 0x2a2400> integer = 1",
                 "<QVariant: 0x275450> string = IrcUser",
                 "<QVariant: 0x2ac0f0> string = 4/mf2hd",
                 "<QVariant: 0x2a1e20> byte array with 7 bytes",
                 "<QVariant: 0x2a2100> boolean = NO"
                 )
                 2012-07-18 14:29:47.242 quassel-for-ios[42671:707] ...Sync
                 2012-07-18 14:29:47.243 quassel-for-ios[42671:707] Remote wants to invoke setAway (object=4/mf2hd, class=IrcUser)
                 */
                /*
                 2012-07-18 14:30:09.877 quassel-for-ios[42671:707] ...list (
                 "<QVariant: 0x2a1d00> integer = 1",
                 "<QVariant: 0x2ac0f0> string = IrcUser",
                 "<QVariant: 0x2a2400> string = 4/meric",
                 "<QVariant: 0x2a1fc0> byte array with 7 bytes",
                 "<QVariant: 0x292380> string = meric"
                 )
                 2012-07-18 14:30:09.878 quassel-for-ios[42671:707] ...Sync
                 2012-07-18 14:30:09.880 quassel-for-ios[42671:707] Remote wants to invoke setNick (object=4/meric, class=IrcUser)
                 */
                /*
                 2012-07-18 14:53:56.935 quassel-for-ios[42741:707] ...Sync
                 2012-07-18 14:53:56.937 quassel-for-ios[42741:707] Remote wants to invoke setServer (object=4/cjanssen, class=IrcUser)
                 2012-07-18 14:53:56.938 quassel-for-ios[42741:707] QuasselCoreConnection handleEvent next block has 115 bytes, input data length is 119 bytes
                 2012-07-18 14:53:56.940 quassel-for-ios[42741:707] ...list (
                 "QVariant(integer(1))",
                 "QVariant(string(IrcUser))",
                 "QVariant(string(4/cjanssen))",
                 "QVariant(byteArray(11))",
                 "QVariant(string(cjanssen))"
                 )
                 2012-07-18 14:53:56.942 quassel-for-ios[42741:707] ...Sync
                 2012-07-18 14:53:56.943 quassel-for-ios[42741:707] Remote wants to invoke setRealName (object=4/cjanssen, class=IrcUser)
                 2012-07-18 14:54:07.578 quassel-for-ios[42741:707] QuasselCoreConnection handleEvent next block has 27 bytes, input data length is 31 bytes
                 2012-07-18 14:54:07.581 quassel-for-ios[42741:707] Deserializing time
                 2012-07-18 14:54:07.583 quassel-for-ios[42741:707] ...list (
                 "QVariant(integer(5))",
                 "QVariant(FIXME)"
                 )
                 */


                /*
                 2012-07-19 22:04:34.341 quassel-for-ios[44351:707] ...list (
                 "QVariant(integer(1))",
                 "QVariant(string(BufferSyncer))",
                 "QVariant(string())",
                 "QVariant(byteArray(16))",
                 "QVariant(BufferId(248))"
                 )
                 2012-07-19 22:04:34.342 quassel-for-ios[44351:707] ...Sync
                 2012-07-19 22:04:34.344 quassel-for-ios[44351:707] Remote wants to invoke markBufferAsRead (object=, class=BufferSyncer)
                 */
                NSString *className = [[v.list objectAtIndex:1] asStringFromStringOrByteArray];
                NSString *objectName = [[v.list objectAtIndex:2] asStringFromStringOrByteArray];
                NSString *functionName = [[v.list objectAtIndex:3] asStringFromStringOrByteArray];
                NSLog(@"[Sync[ Remote wants to invoke %@ (object=%@, class=%@)", functionName, objectName, className);

                if ([className isEqualToString:@"BacklogManager"]) {
                    if ([functionName isEqualToString:@"receiveBacklog"]) {
                        NSArray *messageVariantList = [[v.list objectAtIndex:9] list];
                        NSLog(@"Received %lu messages backlog", (unsigned long)messageVariantList.count);
                        NSMutableArray *messages = [NSMutableArray arrayWithCapacity:messageVariantList.count];
                        [messageVariantList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            // HACK!
                            Message *message = (Message*)[obj message];
                            message.messageFlag = message.messageFlag | MessageFlagBacklog;

                            //NSLog(@"backlog message: %@ %@", obj, [obj message]);
                            [messages addObject:message];
                        }];
                        [self backlogMessagesReceived:messages];
                    }
                } else if ([className isEqualToString:@"BufferSyncer"]) {
                    if ([functionName isEqualToString:@"setLastSeenMsg"]) {
                        /* 2012-07-18 14:28:51.870 quassel-for-ios[42671:707] ...list (
                         "<QVariant: 0x292380> integer = 1",
                         "<QVariant: 0x275450> string = BufferSyncer",
                         "<QVariant: 0x2ac0f0> string = ",
                         "<QVariant: 0x2a1d90> byte array with 14 bytes",
                         "<QVariant: 0x2abd80> bufferId = BufferId(28)",
                         "<QVariant: 0x2a1c90> msgId = MsgId(7909068)"
                         )
                         */
                        BufferId *bufferId = [[v.list objectAtIndex:4] bufferId];
                        MsgId *messageId  = [[v.list objectAtIndex:5] msgId];
                        [self.bufferIdLastSeenMessageIdMap setObject:messageId forKey:bufferId];
                        [self computeBufferActivityForBuffer:bufferId];

                        [delegate quasselLastSeenMsgUpdated:messageId forBuffer:bufferId];
                    } else if ([functionName isEqualToString:@"renameBuffer"]) {
                        // parameters: bufferId and new buffer name
                        BufferId *bufferId = [[v.list objectAtIndex:4] bufferId];
                        NSString *newName = [[v.list objectAtIndex:5] string];

                        BufferInfo *bufferInfo = [bufferIdBufferInfoMap objectForKey:bufferId];
                        bufferInfo.bufferName = newName;

                        [delegate quasselBufferListUpdated];
                    } else if ([functionName isEqualToString:@"mergeBuffersPermanently"]) {
                        [self disconnect];
                    }
                } else if ([className isEqualToString:@"BufferViewConfig"] &&
                           [objectName isEqualToString:@"0"]) {
                    if ([functionName isEqualToString:@"addBuffer"]) {
                        /*
                         2012-07-19 22:02:54.529 quassel-for-ios[44351:707] ...list (
                         "QVariant(integer(1))",                       0
                         "QVariant(string(BufferViewConfig))",         1
                         "QVariant(string(0))",                        2
                         "QVariant(byteArray(9))",                     3
                         "QVariant(BufferId(258))",                    4
                         "QVariant(integer(6))" // position
                         )
                         2012-07-19 22:02:54.530 quassel-for-ios[44351:707] ...Sync
                         2012-07-19 22:02:54.532 quassel-for-ios[44351:707] Remote wants to invoke addBuffer (object=0, class=BufferViewConfig)
                         */
                        BufferId *bufferId = [[v.list objectAtIndex:4] bufferId];
                        NetworkId *networkId = [[bufferIdBufferInfoMap objectForKey:bufferId] networkId];
                        NSMutableArray *bufferList = [networkIdBufferIdListMap objectForKey:networkId];
                        if ([bufferList indexOfObject:bufferId] == NSNotFound) {
                            [bufferList addObject:bufferId];
                            [visibleBufferIdsList addObject:bufferId];
                            [delegate quasselBufferListUpdated];
                            [delegate quasselSwitchToBuffer:bufferId];

                            [self fetchSomeBacklog:bufferId];
                        }
                    } else if ([functionName isEqualToString:@"removeBufferPermanently"]) {
                        /*
                         2012-07-19 22:30:08.830 quassel-for-ios[44375:707] ...list (
                         "QVariant(integer(1))",
                         "QVariant(string(BufferViewConfig))",
                         "QVariant(string(0))",
                         "QVariant(byteArray(23))",
                         "QVariant(BufferId(259))"
                         )
                         2012-07-19 22:30:08.831 quassel-for-ios[44375:707] ...Sync
                         2012-07-19 22:30:08.833 quassel-for-ios[44375:707] Remote wants to invoke removeBufferPermanently (object=0, class=BufferViewConfig)
                         */
                        [self disconnect];
                        //                        BufferId *bufferId = [[v.list objectAtIndex:4] bufferId];
                        //                        NetworkId *networkId = [[bufferIdBufferInfoMap objectForKey:bufferId] networkId];
                        //                        NSMutableArray *bufferList = [networkIdBufferIdListMap objectForKey:networkId];
                        //                        NSLog(@"Removing buffer %d", bufferId.intValue);
                        //                        [bufferList removeObject:bufferId];
                        //                        [visibleBufferIdsList removeObject:bufferId];
                        //                        [delegate quasselBufferListUpdated];
                    } else if ([functionName isEqualToString:@"removeBuffer"]) {
                        /*
                         2012-07-19 22:08:27.521 quassel-for-ios[44375:707] ...list (
                         "QVariant(integer(1))",
                         "QVariant(string(BufferViewConfig))",
                         "QVariant(string(0))",
                         "QVariant(byteArray(12))",
                         "QVariant(BufferId(259))"
                         )
                         2012-07-19 22:08:27.523 quassel-for-ios[44375:707] ...Sync
                         2012-07-19 22:08:27.524 quassel-for-ios[44375:707] Remote wants to invoke removeBuffer (object=0, class=BufferViewConfig)
                         */
                        // Temporarily hiding the buffer
                        [self disconnect];
                        //                        BufferId *bufferId = [[v.list objectAtIndex:4] bufferId];
                        //                        NetworkId *networkId = [[bufferIdBufferInfoMap objectForKey:bufferId] networkId];
                        //                        NSMutableArray *bufferList = [networkIdBufferIdListMap objectForKey:networkId];
                        //                        [bufferList removeObject:bufferId];
                        //                        [visibleBufferIdsList removeObject:bufferId];
                        //                        NSLog(@"Removing buffer %d", bufferId.intValue);
                        //                        [delegate quasselBufferListUpdated];
                    }



                } else if ([className isEqualToString:@"IrcUser"]) {
                    NSArray *splittedObjectName = [objectName componentsSeparatedByString:@"/"];
                    NetworkId *networkId = [[NetworkId alloc] initWithInt:[[splittedObjectName objectAtIndex:0] intValue]];
                    NSString *nick = [splittedObjectName objectAtIndex:1];
                    /*
                     2012-07-18 14:29:13.447 quassel-for-ios[42671:707] ...list (
                     "<QVariant: 0xee934a0> integer = 1",
                     "<QVariant: 0xee8fad0> string = IrcUser",
                     "<QVariant: 0xee8b980> string = 4/sergio",
                     "<QVariant: 0xee92270> byte array with 4 bytes"
                     )
                     2012-07-18 14:29:13.449 quassel-for-ios[42671:707] ...Sync
                     2012-07-18 14:29:13.450 quassel-for-ios[42671:707] Remote wants to invoke quit (object=4/sergio, class=IrcUser)
                     */
                    /*
                     2012-07-18 14:30:04.034 quassel-for-ios[42671:707] ...list (
                     "<QVariant: 0x2a1d90> integer = 1",
                     "<QVariant: 0x292380> string = IrcUser",
                     "<QVariant: 0x2ac0f0> string = 4/onr",
                     "<QVariant: 0x275450> byte array with 11 bytes",
                     "<QVariant: 0x2a2400> string = #startups"
                     )
                     2012-07-18 14:30:04.035 quassel-for-ios[42671:707] ...Sync
                     2012-07-18 14:30:04.037 quassel-for-ios[42671:707] Remote wants to invoke partChannel (object=4/onr, class=IrcUser)
                     */
                    if ([functionName isEqualToString:@"quit"]) {
                        NSMutableDictionary *usersForNetwork = [self.networkIdUserMapMap objectForKey:networkId];
                        IrcUser *ircUser = [usersForNetwork valueForKey:nick];
                        if (ircUser) {
                            NSMutableDictionary *channelsForNetwork = [self.networkIdChannelMapMap objectForKey:networkId];
                            for (IrcChannel *channel in channelsForNetwork.allValues) {
                                [channel partUser:ircUser];
                            }
                            [usersForNetwork removeObjectForKey:nick];
                        }
                    } else if ([functionName isEqualToString:@"partChannel"]) {
                        NSMutableDictionary *usersForNetwork = [self.networkIdUserMapMap objectForKey:networkId];
                        IrcUser *ircUser = [usersForNetwork valueForKey:nick];
                        NSString *channelName = [[v.list objectAtIndex:4] string];
                        NSMutableDictionary *channelsForNetwork = [self.networkIdChannelMapMap objectForKey:networkId];
                        IrcChannel *ircChannel = [channelsForNetwork valueForKey:channelName];

                        if (ircUser && ircChannel) {
                            [ircChannel partUser:ircUser];
                        }
                    }


                } else if ([className isEqualToString:@"Network"]) {
                    /*
                     2012-07-18 02:00:39.502 quassel-for-ios[42048:707] ...list (
                     "<QVariant: 0xce731a0> integer = 1",
                     "<QVariant: 0xce73100> string = Network",
                     "<QVariant: 0xce69890> string = 14",
                     "<QVariant: 0x157830> byte array with 10 bytes",
                     "<QVariant: 0xce739e0> integer = 15"
                     2012-07-18 10:11:38.701 quassel-for-ios[42306:707] Remote wants to invoke setLatency (object=14, class=Network)
                     )
                     */
                    if ([functionName isEqualToString:@"setLatency"]) {

                    } else if ([functionName isEqualToString:@"addIrcUser"]) {
                        /*
                         2012-07-19 21:41:13.705 quassel-for-ios[44279:707] ...list (
                         "QVariant(integer(1))",
                         "QVariant(string(Network))",
                         "QVariant(string(14))", <---- object ID, but how to use it?
                         "QVariant(byteArray(10))",
                         "QVariant(string(shiroki!quassel@nat/trolltech/x-qogwlmohakpjkkpn))"
                         )
                         2012-07-19 21:41:13.707 quassel-for-ios[44279:707] ...Sync
                         2012-07-19 21:41:13.709 quassel-for-ios[44279:707] Remote wants to invoke addIrcUser (object=14, class=Network)
                         */

                        // Die object ID ist vom netzwerk, daher wissen wir das netzwerk
                        NetworkId *networkId = [[NetworkId alloc] initWithInt:[objectName intValue]];
                        IrcUser *ircUser = [[IrcUser alloc] initWithUhost:[[v.list objectAtIndex:4] string]];

                        NSMutableDictionary *usersForNetwork = [self.networkIdUserMapMap objectForKey:networkId];
                        [usersForNetwork setValue:ircUser forKey:ircUser.nick];

                        // on addIrcUser we need to sendInitRequest("IrcUser", objectName + "/" + nick.split("!")[0]);
                        // https://github.com/sandsmark/QuasselDroid/blob/master/QuasselDroid/src/main/java/com/iskrembilen/quasseldroid/io/CoreConnection.java#L1243
                        [self sendCommand:[NSArray arrayWithObjects:[[QVariant alloc] initWithInt:InitRequest],
                                           [[QVariant alloc] initWithString:@"IrcUser"],
                                           [[QVariant alloc] initWithString:[NSString stringWithFormat:@"%@/%@",[[v.list objectAtIndex:2] string],ircUser.nick]],
                                           nil
                                           ]];

                    } else if ([functionName isEqualToString:@"addIrcChannel"]) {
                        NetworkId *networkId = [[NetworkId alloc] initWithInt:[objectName intValue]];
                        NSString *bufferName =[[v.list objectAtIndex:4] string];
                        NSMutableDictionary *channelsForNetwork = [self.networkIdChannelMapMap objectForKey:networkId];
                        IrcChannel *ircChannel = [channelsForNetwork valueForKey:bufferName];
                        if (!ircChannel) {
                            IrcChannel *ircChannel = [[IrcChannel alloc] initWithName:bufferName];
                            // FIXME set topic etc
                            [channelsForNetwork setObject:ircChannel forKey:bufferName];
                            [self sendCommand:[NSArray arrayWithObjects:[[QVariant alloc] initWithInt:InitRequest],
                                           [[QVariant alloc] initWithString:@"IrcChannel"],
                                           [[QVariant alloc] initWithString:[NSString stringWithFormat:@"%d/%@",networkId.intValue,bufferName]],
                                           nil
                                           ]];
                            // Adding to local visibleBufferIdsList is indirectly done in ensureBufferExists
                            // Adding to remote BufferViewConfig too..
                        }
                    } else {
                        NSLog(@"class Network <%@> %@", objectName, functionName);
                    }





                } else if ([className isEqualToString:@"IrcChannel"]) {

                    /*
                     2012-07-18 14:29:15.401 quassel-for-ios[42671:707] ...list (
                     "<QVariant: 0x2a1f30> integer = 1",
                     "<QVariant: 0x275450> string = IrcChannel",
                     "<QVariant: 0x292380> string = 4/#quassel",
                     "<QVariant: 0x2a1e20> byte array with 12 bytes",
                     "<QVariant: 0x2a2100> list = (\n    roxahris\n)",
                     "<QVariant: 0x2b1850> list = (\n    \"\"\n)"
                     )
                     2012-07-18 14:29:15.403 quassel-for-ios[42671:707] ...Sync
                     2012-07-18 14:29:15.405 quassel-for-ios[42671:707] Remote wants to invoke joinIrcUsers (object=4/#quassel, class=IrcChannel)
                     */
                    if ([functionName isEqualToString:@"joinIrcUsers"]) {
                        NSArray *list =[[v.list objectAtIndex:4] list];
                        NSLog(@"class IrcChannel <%@> joinIrcUsers %@", objectName, list);
                        NSArray *splittedObjectName = [objectName componentsSeparatedByString:@"/"];
                        NetworkId *networkId = [[NetworkId alloc] initWithInt:[[splittedObjectName objectAtIndex:0] intValue]];
                        NSMutableDictionary *channelsForNetwork = [self.networkIdChannelMapMap objectForKey:networkId];
                        IrcChannel *ircChannel = [channelsForNetwork valueForKey:[splittedObjectName objectAtIndex:1]];

                        NSArray *userList = [[v.list objectAtIndex:4] list];
                        for (NSString *nick in userList) {
                            IrcUser *ircUser = [self ircUserForNetworkId:networkId andNick:nick];
                            if (ircUser) {
                                [ircChannel addUser:ircUser];
                            } else {
                                // Does actually not happen, the core invokes addIrcUser for each user before
                                NSLog(@"FIXME create user %@ %@", nick, objectName);
                            }
                        }
                    } else {
                        NSLog(@"UNHANDLED class IrcChannel <%@> %@", objectName, functionName);
                    }

                } else {
                    NSLog(@"UNKNOWN class %@ <%@>", className, objectName);
                }



                /*
                 */


            } else if (requestType == RpcCall) { // 2
                NSLog(@"...RpcCall");
                /*
                 2012-07-10 17:01:07.276 quassel-for-ios[34759:707] ...list (
                 "<QVariant: 0x161cf0> integer = 2",
                 "<QVariant: 0x161250> FIXME",
                 "<QVariant: 0x161270> message = <mgoetz!~mgoetz@noreg.fauleban.de> !"
                 )
                 */
                NSString *method = [[v.list objectAtIndex:1] asStringFromStringOrByteArray];

                if ([method isEqualToString:@"2displayMsg(Message)"]) {
                    NSLog(@"RPC: Display Mesage");
                    QVariant *variant = [v.list objectAtIndex:2];
                    Message *message =  [variant message];
                    [self messageReceived:message];



                } else if ([method isEqualToString:@"__objectRenamed__"]) {
                    // 						} else if(functionName.equals("__objectRenamed__") && ((String)packedFunc.get(0).getData()).equals("IrcUser")) {

                    /*
                     2012-07-18 14:30:09.870 quassel-for-ios[42671:707] ...list (
                     "<QVariant: 0xee934a0> integer = 2",
                     "<QVariant: 0xee905d0> string = __objectRenamed__",
                     "<QVariant: 0xee8b980> byte array with 7 bytes",
                     "<QVariant: 0xee871b0> string = 4/meric",
                     "<QVariant: 0xee8fa50> string = 4/meric_"
                     )
                     2012-07-18 14:30:09.872 quassel-for-ios[42671:707] ...RpcCall
                     2012-07-18 14:30:09.873 quassel-for-ios[42671:707] RPC: Core wants to call unknown method
                     */
                    NSString *class = [[v.list objectAtIndex:2] asStringFromStringOrByteArray];
                    if ([class isEqualToString:@"IrcUser"]) {
                        NSString *old = [[v.list objectAtIndex:4] asStringFromStringOrByteArray];
                        NSArray *oldSplit = [old componentsSeparatedByString:@"/"];
                        NSString *oldNick = [oldSplit objectAtIndex:1];
                        NSString *new = [[v.list objectAtIndex:3] asStringFromStringOrByteArray];
                        NSArray *newSplit = [new componentsSeparatedByString:@"/"];
                        NSString *newNick = [newSplit objectAtIndex:1];

                        NetworkId *networkId = [[NetworkId alloc]initWithInt:[[oldSplit objectAtIndex:0] intValue]];

                        NSLog(@"%@: %@ -> %@", [self.networkIdNetworkNameMap objectForKey:networkId], oldNick, newNick);

                        NSMutableDictionary *usersForNetwork = [self.networkIdUserMapMap objectForKey:networkId];
                        IrcUser *ircUser = [usersForNetwork valueForKey:oldNick];
                        [usersForNetwork removeObjectForKey:oldNick];
                        ircUser.nick = newNick;
                        [usersForNetwork setValue:ircUser forKey:newNick];
                    } else {
                        NSLog(@"FIXME unknown __objectRenamed__ %@", class);
                    }

                } else if ([method isEqualToString:@"2networkCreated(NetworkId)"]) {
                    NSLog(@"RPC: Network created");
                    [self disconnect];
                } else if ([method isEqualToString:@"2networkRemoved(NetworkId)"]) {
                    NSLog(@"RPC: Network removed");
                    [self disconnect];
                } else {
                    NSLog(@"RPC: Core wants to call unknown method < %@ >", method);
                    if (v.dict)
                        NSLog(@"    parameters < %@ >", v.dict.allKeys);
                }

            } else if (requestType == InitRequest) { // 3
                NSLog(@"...InitRequest");

            } else if (requestType == InitData) { // 4
                NSLog(@"...InitData %@", [[v.list objectAtIndex:1] asStringFromStringOrByteArray]);
                /*
                 2012-07-19 22:48:51.484 quassel-for-ios[44460:707] ...list (
                 "QVariant(integer(4))",
                 "QVariant(byteArray(12))",
                 "QVariant(string())",
                 "QVariant(dictionary({\n    LastSeenMsg = \"QVariant(list((\\n    \\\"QVariant(BufferId(255))\\\",\\n    \\\"QVariant(MsgId(7863649))\\\",\\n    \\\"QVariant(BufferId(260))\\\",\\n    \\\"QVariant(MsgId(7951196))\\\",\\n    \\\"QVariant(BufferId(248))\\\",\\n    \\\"QVariant(MsgId(7950979))\\\",\\n    \\\"QVariant(BufferId(249))\\\",\\n    \\\"QVariant(MsgId(7920611))\\\",\\n    \\\"QVariant(BufferId(250))\\\",\\n    \\\"QVariant(MsgId(7941053))\\\",\\n    \\\"QVariant(BufferId(252))\\\",\\n    \\\"QVariant(MsgId(7920611))\\\"\\n)))\";\n    MarkerLines = \"QVariant(list((\\n    \\\"QVariant(BufferId(255))\\\",\\n    \\\"QVariant(MsgId(7863649))\\\",\\n    \\\"QVariant(BufferId(248))\\\",\\n    \\\"QVariant(MsgId(7950979))\\\",\\n    \\\"QVariant(BufferId(249))\\\",\\n    \\\"QVariant(MsgId(7920611))\\\",\\n    \\\"QVariant(BufferId(250))\\\",\\n    \\\"QVariant(MsgId(7941053))\\\",\\n    \\\"QVariant(BufferId(252))\\\",\\n    \\\"QVariant(MsgId(7920611))\\\"\\n)))\";\n}))"
                 )
                 2012-07-19 22:48:51.487 quassel-for-ios[44460:707] ...InitData BufferSyncer
                 */
                /*
                 2012-07-19 22:48:51.494 quassel-for-ios[44460:707] ...list (
                 "QVariant(integer(4))",
                 "QVariant(byteArray(16))",
                 "QVariant(string(0))",
                 "QVariant(dictionary({\n    BufferList = \"QVariant(list((\\n    \\\"QVariant(BufferId(259))\\\",\\n    \\\"QVariant(BufferId(249))\\\",\\n    \\\"QVariant(BufferId(248))\\\",\\n    \\\"QVariant(BufferId(250))\\\",\\n    \\\"QVariant(BufferId(255))\\\",\\n    \\\"QVariant(BufferId(252))\\\",\\n    \\\"QVariant(BufferId(257))\\\",\\n    \\\"QVariant(BufferId(258))\\\",\\n    \\\"QVariant(BufferId(260))\\\"\\n)))\";\n    RemovedBuffers = \"QVariant(list((\\n)))\";\n    TemporarilyRemovedBuffers = \"QVariant(list((\\n)))\";\n    addNewBuffersAutomatically = \"QVariant(boolean(NO))\";\n    allowedBufferTypes = \"QVariant(integer(15))\";\n    bufferViewName = \"QVariant(string(Alle Chats))\";\n    disableDecoration = \"QVariant(boolean(NO))\";\n    hideInactiveBuffers = \"QVariant(boolean(NO))\";\n    minimumActivity = \"QVariant(integer(0))\";\n    networkId = \"QVariant(NetworkId(0))\";\n    sortAlphabetically = \"QVariant(boolean(NO))\";\n}))"
                 )
                 2012-07-19 22:48:51.497 quassel-for-ios[44460:707] ...InitData BufferViewConfig
                 */
                NSString *className = [[v.list objectAtIndex:1] asStringFromStringOrByteArray];
                NSString *objectName = [[v.list objectAtIndex:2] asStringFromStringOrByteArray];
                if ([className isEqualToString:@"BufferViewConfig"] && [objectName isEqualToString:@"0"]) {
                    NSDictionary *initData = [[v.list objectAtIndex:3] dict];
                    NSArray *bufferList = [[initData objectForKey:@"BufferList"] list];
                    [bufferList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        BufferId *bufferId = [obj bufferId];


                        BufferInfo *bufferInfo = [bufferIdBufferInfoMap objectForKey:bufferId];

                        if (bufferInfo && bufferInfo.bufferType != StatusBuffer) {
                            NSMutableArray *a = [networkIdBufferIdListMap objectForKey:bufferInfo.networkId];
                            if (!a) {
                                a = [NSMutableArray array];
                                [networkIdBufferIdListMap setObject:a forKey:bufferInfo.networkId];
                            }
                            [visibleBufferIdsList addObject:bufferId];
                            [a addObject:bufferId];
                        } else if (bufferInfo) {
                            [visibleBufferIdsList addObject:bufferId];
                        } else {
                            NSLog(@"WARNING: No BufferInfo for %@ found", bufferId);
                        }
                    }];


                    // Now request all backlogs (except the one that was prefetched)
                    for (int i = 0; i < visibleBufferIdsList.count; i++) {
                        BufferId* bufferId = [visibleBufferIdsList objectAtIndex:i];
                        if (![backlogRequestedForAlreadyBufferIdSet containsObject:bufferId]) {
                            [backlogRequestedForAlreadyBufferIdSet addObject:bufferId];
                            [self fetchSomeBacklog:bufferId amount:45];
                        }
                    }

                    // ^^ the above is a lie
                    // We only request the user data now
                    [neworkIdList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        [self sendCommand:[NSArray arrayWithObjects:[[QVariant alloc] initWithInt:InitRequest],
                                           [[QVariant alloc] initWithString:@"Network"],
                                           [[QVariant alloc] initWithString:[NSString stringWithFormat:@"%d",[obj intValue]]],
                                           nil
                                           ]];
                    }];


                    //NSLog(@"visibleBufferIdsList = %@", visibleBufferIdsList);
                    // This moves on the UI:
                    [delegate quasselBufferListReceived];
                    [delegate quasselAllNetworkInitReceived];


                } else if ([className isEqualToString:@"BufferSyncer"] && [objectName isEqualToString:@""]) {
                    NSDictionary *initData = [[v.list objectAtIndex:3] dict];
                    NSArray *lastSeenMsgData = [[initData objectForKey:@"LastSeenMsg"] list];

                    bufferIdLastSeenMessageIdMap = [NSMutableDictionary dictionaryWithCapacity:lastSeenMsgData.count/2];

                    // list contains alternating BufferId and MessageId
                    for (int i = 0; i < lastSeenMsgData.count; i+=2) {
                        BufferId *bufferId = [[lastSeenMsgData objectAtIndex:i] bufferId];
                        MsgId *msgId = [[lastSeenMsgData objectAtIndex:i+1] msgId];
                        [bufferIdLastSeenMessageIdMap setObject:msgId forKey:bufferId];
                    }
                    //NSLog(@"bufferIdLastSeenMessageIdMap = %@", bufferIdLastSeenMessageIdMap);

                } else if ([className isEqualToString:@"Network"]) {
                    [self handleReceivedNetworkInit:v.list];
                }

            } else if (requestType == HeartBeat) { // 5
                NSLog(@"...HeartBeat");

                /* 2012-07-09 14:00:13.704 quassel-for-ios[32998:707] array with 2 entries
                 2012-07-09 14:00:13.705 quassel-for-ios[32998:707] Deserializing integer
                 2012-07-09 14:00:13.707 quassel-for-ios[32998:707] Decoded value <QVariant: 0x124e80> integer = 5
                 2012-07-09 14:00:13.708 quassel-for-ios[32998:707] Deserializing time
                 2012-07-09 14:00:13.710 quassel-for-ios[32998:707] Decoded value <QVariant: 0xde41500> FIXME
                 2012-07-09 14:00:13.711 quassel-for-ios[32998:707] ...list (
                 "<QVariant: 0x124e80> integer = 5",
                 "<QVariant: 0xde41500> FIXME"
                 )
                 */
                //                NSArray *initial = [NSMutableDictionary dictionaryWithCapacity:7];
                //                [initial setValue:[[QVariant alloc] initWithString:@"ClientLogin"] forKey:@"MsgType"];
                [self sendCommand:[NSArray arrayWithObjects:[[QVariant alloc] initWithInt:HeartBeatReply], [v.list lastObject],nil]];

            } else if (requestType == HeartBeatReply) { // 5
                NSLog(@"...HeartBeatReply");



            } else {
                NSLog(@"...Unknown request type");
            }
        }

    } else {
        NSLog(@"ERROR: Received data in unknown state!");
    }

    [socket readDataWithTimeout:-1 tag:-1];
}

- (void) ensureBufferExists:(BufferInfo*)bufferInfo
{
    BufferId *bufferId = bufferInfo.bufferId;
    [bufferIdBufferInfoMap setObject:bufferInfo forKey:bufferId];
    NSMutableArray *messageList = [bufferIdMessageListMap objectForKey:bufferId];
    if (!messageList) {
        NSLog(@"ensureBufferExists created new buffer");
        messageList = [NSMutableArray array];
        [bufferIdMessageListMap setObject:messageList forKey:bufferId];
        NSMutableArray *bufferList = [networkIdBufferIdListMap objectForKey:bufferInfo.networkId];
        if ([bufferList indexOfObject:bufferId] == NSNotFound) {
            [bufferList  addObject:bufferId];
        }

        // Add to core list so it appears next time
        NSMutableArray *commandArray = [NSMutableArray array];
        [commandArray addObject:[[QVariant alloc] initWithInt:Sync]];
        [commandArray addObject:[[QVariant alloc] initWithString:@"BufferViewConfig"]];
        [commandArray addObject:[[QVariant alloc] initWithString:@"0"]];
        [commandArray addObject:[[QVariant alloc] initWithString:@"requestAddBuffer"]];
        [commandArray addObject:[[QVariant alloc] initWithBufferId:bufferId]];
        [commandArray addObject:[[QVariant alloc] initWithInt:INT_MAX]];
        [self sendCommand:commandArray];
        [visibleBufferIdsList addObject:bufferId];

        [delegate quasselBufferListUpdated];
        [delegate quasselSwitchToBuffer:bufferId];
    }

}

- (void) backlogMessagesReceived:(NSMutableArray*)messagesReceived
{
    if (messagesReceived.count == 0)
        return;
    Message *firstReceivedMessage = [messagesReceived objectAtIndex:0];
    [self ensureBufferExists:firstReceivedMessage.bufferInfo];
    BufferId *bufferId = firstReceivedMessage.bufferInfo.bufferId;

    // first remove all messages we already had
    NSMutableArray *messageList = [bufferIdMessageListMap objectForKey:bufferId];
    [messagesReceived removeObjectsInArray:messageList];

    if (messagesReceived.count == 0)
        return;

    firstReceivedMessage = [messagesReceived objectAtIndex:0];
    Message *lastReceivedMessage = [messagesReceived lastObject];

    Message *firstMessageWeHave = messageList.count == 0 ? nil : [messageList objectAtIndex:0];
    Message *lastMessageWeHave = messageList.count == 0 ? nil : [messageList lastObject];


    //    for (int i = 0; i < messageList.count; i++)
    //        NSLog(@"We have %d %@", i, [messageList objectAtIndex:i]);
    //    for (int i = 0; i < messagesReceived.count; i++)
    //        NSLog(@"We want to add %d %@", i, [messagesReceived objectAtIndex:i]);

    if (!firstMessageWeHave && !lastMessageWeHave) {
        // Easy case: We have no messages yet
        NSLog(@"backlogMessagesReceived Easy case, no messages yet.");
        [messageList addObjectsFromArray:messagesReceived];
        [self computeBufferActivityForBuffer:bufferId];
        [delegate quasselMessagesReceived:messagesReceived received:ReceiveStyleAppended];

    } else if (lastReceivedMessage.messageId.intValue < firstMessageWeHave.messageId.intValue) {
        // FIXME Case1: Is lastReceivedMessage.id < firstMessageWeGot.id
        //NSLog(@"backlogMessagesReceived Would prepend %d messages", messagesReceived.count);
        [messageList insertObjects:messagesReceived atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, messagesReceived.count)]];
        [self computeBufferActivityForBuffer:bufferId];
        [delegate quasselMessagesReceived:messagesReceived received:ReceiveStylePrepended];

    } else if  (firstReceivedMessage.messageId.intValue > lastMessageWeHave.messageId.intValue){
        // FIXME Case2: Is firstReceivedMessage.id > lastMessageWeGot.id
        //NSLog(@"backlogMessagesReceived Would apppend %d messages", messagesReceived.count);
        [messageList addObjectsFromArray:messagesReceived];
        [self computeBufferActivityForBuffer:bufferId];
        [delegate quasselMessagesReceived:messagesReceived received:ReceiveStyleAppended];

    } else {
        // FIXME We assume that the third case cannot be
        NSLog(@"backlogMessagesReceived THIRD CASE!");
    }

}


- (void) messageReceived:(Message*)message
{
    NSLog(@"messageReceived %@", message);
    BufferId *bufferId = message.bufferInfo.bufferId;
    [self ensureBufferExists:message.bufferInfo];

    NSMutableArray *messageList = [bufferIdMessageListMap objectForKey:message.bufferInfo.bufferId];

    Message *firstMessage = messageList.count == 0 ? nil : [messageList objectAtIndex:0];
    Message *previousMessage = messageList.count == 0 ? nil : [messageList lastObject];

    if (!firstMessage || !previousMessage || [previousMessage.messageId intValue] < [message.messageId intValue]) {
        [messageList addObject:message];
        [self computeBufferActivityForBuffer:bufferId];
        //NSLog(@"messageReceived Appending message");
        [delegate quasselMessageReceived:message received:ReceiveStyleAppended onIndex:messageList.count-1];
    } else if ([firstMessage.messageId intValue] > [message.messageId intValue]) {
        //NSLog(@"messageReceived Prepending message");
        [messageList insertObject:message atIndex:0];
        [self computeBufferActivityForBuffer:bufferId];
        [delegate quasselMessageReceived:message received:ReceiveStylePrepended onIndex:0];
    } else {
        // FIXME
        //NSLog(@"messageReceived dont know what do about message!");
        //NSLog(@"messageReceived inserting!");

        int indexToUse = 0;
        for (int i = 0; i < messageList.count; i++) {
            if ([[[messageList objectAtIndex:i] messageId] intValue] == message.messageId.intValue) {
                indexToUse = -1;
                break;
            }
            if ([[[messageList objectAtIndex:i] messageId] intValue] > message.messageId.intValue) {
                indexToUse = i;
                break;
            }
            indexToUse = i;
        }

        if (indexToUse == -1) {
            NSLog(@"messageReceived Message already received, ignoring");
        } else {
            NSLog(@"messageReceived Inserting message at index %d", indexToUse);
            [messageList insertObject:message atIndex:indexToUse];
            [self computeBufferActivityForBuffer:bufferId];
            [delegate quasselMessageReceived:message received:ReceiveStyleBacklog onIndex:indexToUse];
        }
        //int i = 0 / 0;
    }
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    if (socket != sock) {
        NSLog(@"Warning: socketDidSecure for wrong socket! %@ != %@", socket, sock);
        return;
    }
    [delegate quasselEncrypted];
    NSLog(@"QuasselCoreConnection socketDidSecure Socket TLS established");
    [self performSelector:@selector(sendClientLogin) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
    //[self sendClientLogin];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    if (socket != sock) {
        NSLog(@"Warning: socketDidDisconnect for wrong socket! %@ != %@", socket, sock);
        return;
    }
    NSLog(@"QuasselCoreConnection socketDidDisconnect %@", error);

    [self performSelector:@selector(socketDidDisconnectMT:) onThread:[NSThread mainThread] withObject:[error copy] waitUntilDone:NO];
}

- (void)socketDidDisconnectMT:(NSError *)error
{
    if (error)
        lastErrorMsg = error.localizedDescription;
    [delegate quasselSocketDidDisconnect:lastErrorMsg];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    if (socket != sock) {
        NSLog(@"Warning: didConnectToHost for wrong socket! %@ != %@", socket, sock);
        return;
    }
    inputData = [[NSMutableData alloc] initWithCapacity:64*1024];

    serverSupportsCompression = NO;
    compressed = NO;
    uncompressedInputDataCounter = 0;
    inputDataCounter = 0;


    NSLog(@"QuasselCoreConnection didConnectToHost");


    [self performSelector:@selector(socketDidConnectMT) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

- (void) socketDidConnectMT
{
    NSLog(@"QuasselCoreConnection socketDidConnectMT");

    [delegate quasselConnected];

    NSDictionary *initial = [NSMutableDictionary dictionaryWithCapacity:7];
    [initial setValue:[[QVariant alloc] initWithString:@"Jun 10 2012 17:00:00"] forKey:@"ClientDate"];
    [initial setValue:[[QVariant alloc] initWithBoolean:YES] forKey:@"UseSsl"];
    [initial setValue:[[QVariant alloc] initWithString:@"Quassel for iOS"] forKey:@"ClientVersion"];
    [initial setValue:[[QVariant alloc] initWithBoolean:YES] forKey:@"UseCompression"];
    [initial setValue:[[QVariant alloc] initWithString:@"ClientInit"] forKey:@"MsgType"];
    [initial setValue:[[QVariant alloc] initWithString:@"Quassel for iOS"] forKey:@"ClientVersion"];
    [initial setValue:[[QVariant alloc] initWithInteger:[NSNumber numberWithInt:10]] forKey:@"ProtocolVersion"];

    [self sendQVariantMap:initial];

    state = SentClientInit;
}

- (void)socket:(GCDAsyncSocket*)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    NSLog(@"QuasselCoreConnection didReadPartialDataOfLength of %lu (%lu bytes in buffer)",(unsigned long)partialLength,
          (unsigned long)inputData.length);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (socket != sock) {
        NSLog(@"Warning: didReadData for wrong socket! %@ != %@", socket, sock);
        return;
    }

    inputDataCounter += data.length;

    //NSLog(@"QuasselCoreConnection handleEvent bytes available %@", [inputStream hasBytesAvailable]? @"YES" : @"NO");
    [inputData appendData:data];

#ifdef QUASSEL_DEBUG_PROTOCOL
    NSLog(@"QuasselCoreConnection didReadData NSStreamEventHasBytesAvailable %d bytes in buffer",
          inputData.length);
#endif


    while (inputData.length >= 4) {
        int blockLength = (int)*((int*)(inputData.bytes));
        blockLength = CFSwapInt32BigToHost(blockLength);
#ifdef QUASSEL_DEBUG_PROTOCOL
        NSLog(@"QuasselCoreConnection didReadData next block has %d bytes, input data length is %d bytes",blockLength, inputData.length);
#endif
        if(inputData.length-4 >= blockLength) {
            // NSData *serializedVariant = [NSData dataWithBytesNoCopy:(void*)inputData.bytes+4 length:blockLength freeWhenDone:NO];

            NSData *serializedVariant;
            if (compressed) {
                NSData *encodedByteArray = [NSData dataWithBytesNoCopy:(void*)inputData.bytes+4 length:blockLength-4 freeWhenDone:NO];
                int bytesRead = 0;
                NSData *qba = [QVariant deserializeByteArray:encodedByteArray bytesRead:&bytesRead];
                serializedVariant = [QuasselUtils qUncompress:qba.bytes count:qba.length];
                uncompressedInputDataCounter += serializedVariant.length;
                //NSLog(@"Decompressed %d bytes to %lu", blockLength, (unsigned long)serializedVariant.length);
            } else {
                serializedVariant = [NSData dataWithBytesNoCopy:(void*)inputData.bytes+4 length:blockLength freeWhenDone:NO];
            }

            int bytesRead = 0;
            QVariant *v = [[QVariant alloc] initWithSerialization:serializedVariant bytesRead:&bytesRead];
            if (bytesRead != serializedVariant.length) {
                NSLog(@"QuasselCoreConnection didReadData ERROR: Didnt deserialize all data, something is weird (bytesRead = %d, length = %lu)", bytesRead, (unsigned long)serializedVariant.length);
                return;
            } else {
                //[self handleReceivedVariant:v];
                //NSLog(@"QuasselCoreConnection didReadData Will handle variant with %d bytes on main thread", serializedVariant.length);
                [self performSelectorOnMainThread:@selector(handleReceivedVariant:) withObject:v waitUntilDone:NO];
            }
            [inputData replaceBytesInRange:NSMakeRange(0, blockLength+4)  withBytes:NULL length:0];
        } else {
            break;
        }
    }
    if (inputData.length > 0) {
        //NSLog(@"QuasselCoreConnection didReadData, remaining %lu bytes in buffer", (unsigned long)inputData.length);

        // schedule more reading (this will wait for new data)
        [socket readDataWithTimeout:-1 tag:-1];
    } else if (socket.isSecure) {
        // schedule more reading without timeout (but only if we are encrypted)
        [socket readDataWithTimeout:-1 tag:-1];
    }

    if (compressed) {
    NSLog(@"Received %@ and decompressed to %@ (Ratio=%5.2f)",
          [QuasselUtils transformedByteValue:inputDataCounter],
          [QuasselUtils transformedByteValue:uncompressedInputDataCounter],
          (float)uncompressedInputDataCounter / (float)inputDataCounter );
    } else {
        NSLog(@"Received %@",
              [QuasselUtils transformedByteValue:inputDataCounter]);
    }


}

- (void) setLastSeenMsg:(MsgId*)msgId forBuffer:(BufferId*)bufferId
{
    MsgId *currentLastSeenMsg = [bufferIdLastSeenMessageIdMap objectForKey:bufferId];
    if (currentLastSeenMsg && [currentLastSeenMsg intValue] > [msgId intValue])
        return;
    [bufferIdLastSeenMessageIdMap setObject:msgId forKey:bufferId];
    [[bufferIdBufferInfoMap objectForKey:bufferId] setBufferActivity:BufferActivityNoActivity];

    [self computeBufferActivityForBuffer:bufferId];
    [delegate quasselLastSeenMsgUpdated:msgId forBuffer:bufferId];


    NSMutableArray *commandArray = [NSMutableArray array];
    [commandArray addObject:[[QVariant alloc] initWithInt:Sync]];
    [commandArray addObject:[[QVariant alloc] initWithString:@"BufferSyncer"]];
    [commandArray addObject:[[QVariant alloc] initWithString:@""]];
    [commandArray addObject:[[QVariant alloc] initWithString:@"requestSetLastSeenMsg"]]; // als QBA!
    [commandArray addObject:[[QVariant alloc] initWithBufferId:bufferId]];
    [commandArray addObject:[[QVariant alloc] initWithMsgId:msgId]];
    [self sendCommand:commandArray];

}

- (MsgId*) lastSeenMsgForBuffer:(BufferId*)bufferId
{
    return [bufferIdLastSeenMessageIdMap objectForKey:bufferId];
}

- (enum BufferActivity) bufferActivityForBuffer:(BufferId*)bufferId
{
    NSNumber *activity = [bufferIdBufferActivityMap objectForKey:bufferId];
    if (!activity)
        return BufferActivityNoActivity;
    return (enum BufferActivity)[activity intValue];
}

- (void) computeBufferActivityForBuffer:(BufferId*)bufferId
{
    MsgId *lastSeenForBuffer = [self lastSeenMsgForBuffer:bufferId];
    //NSLog(@"computeBufferActivityForBuffer Last seen msg ID is = %@", lastSeenForBuffer);
    NSArray *messages = [self.bufferIdMessageListMap objectForKey:bufferId];

    __block enum BufferActivity computedActivity = BufferActivityNoActivity;
    [messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Message *message = obj;
        if (lastSeenForBuffer && lastSeenForBuffer.intValue >= message.messageId.intValue) {
            //NSLog(@"computeBufferActivityForBuffer %d RETURNING,LASTSEEN %@", idx, message);
            *stop = YES;
            return;
        } else if (message.messageType == MessageTypeAction
                   || message.messageType == MessageTypePlain) {
            computedActivity = BufferActivityNewMessage;
            //NSLog(@"computeBufferActivityForBuffer %d RETURNING,CHAT %@", idx, message);
            *stop = YES;
            return;
        } else {
            //NSLog(@"computeBufferActivityForBuffer%d OTHERACTIVITY %@", idx, message);
            computedActivity = BufferActivityOtherActivity;
        }
    }];

    [bufferIdBufferActivityMap setObject:[NSNumber numberWithInt:computedActivity] forKey:bufferId];
}

- (int) computeUnreadCountForBuffer:(BufferId*)bufferId
{
    MsgId *lastSeenMsgId = [self lastSeenMsgForBuffer:bufferId];
    if (!lastSeenMsgId)
        return 0;
    NSArray *messages = [bufferIdMessageListMap objectForKey:bufferId];
    __block int unreadCount = 0;
    [messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MsgId *currentId = [obj messageId];
        NSLog(@"Comparing %@ (current) with %@ (last seen)", currentId, lastSeenMsgId);
        if ([currentId isEqual:lastSeenMsgId]) {
            NSLog(@"EQUAL!");
            *stop = YES;
            return;
        }
        unreadCount++;
    }];
    return unreadCount;
    //
    //    for (int i = messages.count-1; i >= 0; i--)
    //    {
    //        if ([[[messages objectAtIndex:i] messageId] isEqual:lastSeenMsgId]) {
    //            int unreadCount = messages.count - i - 1;
    //            return unreadCount;
    //        }
    //    }
    //    return messages.count;
}

- (void) sendMessage:(NSString*)msg toBuffer:(BufferId*)bufferId
{
    NSMutableString *actualCommand;
    if ([msg hasPrefix:@"/"]) {
        NSArray *components = [msg componentsSeparatedByString:@" "];
        actualCommand = [NSMutableString stringWithCapacity:msg.length];
        [actualCommand appendString:[[components objectAtIndex:0] uppercaseString]];
        for (int i = 1; i < components.count; i++) {
            [actualCommand appendString:@" "];
            [actualCommand appendString:[components objectAtIndex:i]];
        }
    } else {
        actualCommand = [NSMutableString stringWithFormat:@"/SAY %@", msg];
    }
    NSLog(@"sendMessage %@", actualCommand);
    NSMutableArray *commandArray = [NSMutableArray array];
    [commandArray addObject:[[QVariant alloc] initWithInt:RpcCall]];
    [commandArray addObject:[[QVariant alloc] initWithString:@"2sendInput(BufferInfo,QString)"]];
    [commandArray addObject:[[QVariant alloc] initWithBufferInfo:[self.bufferIdBufferInfoMap objectForKey:bufferId]]];
    [commandArray addObject:[[QVariant alloc] initWithString:actualCommand]];
    [self sendCommand:commandArray];
}

// http://code.woboq.org/kde/quassel/src/client/clientuserinputhandler.cpp.html#_ZN22ClientUserInputHandler12switchBufferERK9NetworkIdRK7QString
// http://code.woboq.org/kde/quassel/src/uisupport/nickview.cpp.html#_ZN8NickView10startQueryERK11QModelIndex
- (void) openQueryBufferForUser:(IrcUser*)user onNetwork:(NetworkId*)networkId
{
    // Find out if there is a buffer for that nick
    NSArray *bufferList = [networkIdBufferIdListMap objectForKey:networkId];
    for (BufferId *bufferId in bufferList) {
        BufferInfo *bufferInfo = [bufferIdBufferInfoMap objectForKey:bufferId];
        if ([[bufferInfo.bufferName lowercaseString] isEqualToString:[user.nick lowercaseString]]) {
            // yay we found it
            [delegate quasselSwitchToBuffer:bufferId];
            return;
        }
    }

    // Find out if there is a hidden buffer for that nick?
    // A hidden buffer is in the BufferInfos, but not in the BufferViewConfig
    for (BufferInfo *bufferInfo in bufferIdBufferInfoMap.allValues) {
        if ([bufferInfo.networkId isEqual:networkId] && [[bufferInfo.bufferName lowercaseString] isEqualToString:[user.nick lowercaseString]]) {
            BufferId *bufferId = bufferInfo.bufferId;
//            NSMutableArray *bufferList = [networkIdBufferIdListMap objectForKey:networkId];
//            [bufferList addObject:bufferInfo.bufferId];
//            [visibleBufferIdsList addObject:bufferId];
//            [delegate quasselBufferListUpdated];
//            [delegate quasselSwitchToBuffer:bufferId];

            // invoke it remotely
            NSMutableArray *commandArray = [NSMutableArray array];
            [commandArray addObject:[[QVariant alloc] initWithInt:Sync]];
            [commandArray addObject:[[QVariant alloc] initWithString:@"BufferViewConfig"]];
            [commandArray addObject:[[QVariant alloc] initWithString:@"0"]];
            [commandArray addObject:[[QVariant alloc] initWithString:@"requestAddBuffer"]];
            [commandArray addObject:[[QVariant alloc] initWithBufferId:bufferId]];
            [commandArray addObject:[[QVariant alloc] initWithInt:INT_MAX]];
            [self sendCommand:commandArray];

            return;
        }
    }
    /*
     BufferId *bufferId = [[v.list objectAtIndex:4] bufferId];
     NetworkId *networkId = [[bufferIdBufferInfoMap objectForKey:bufferId] networkId];
     NSMutableArray *bufferList = [networkIdBufferIdListMap objectForKey:networkId];
     if ([bufferList indexOfObject:bufferId] == NSNotFound) {
     [bufferList addObject:bufferId];
     [visibleBufferIdsList addObject:bufferId];
     [delegate quasselBufferListUpdated];
     [delegate quasselSwitchToBuffer:bufferId];
     }
     */



    // request to open a buffer for that nick
    [self sendMessage:[NSString stringWithFormat:@"/QUERY %@",user.nick] toBuffer:[[networkIdServerBufferInfoMap objectForKey:networkId] bufferId]];
}

- (IrcUser*) ircUserForNetworkId:(NetworkId*)networkId andNick:(NSString*)nick
{
    NSMutableDictionary *usersForNetwork = [self.networkIdUserMapMap objectForKey:networkId];
    return [usersForNetwork valueForKey:nick];
}

- (NSArray*) ircUsersForChannelWithBufferId:(BufferId*)bufferId
{
    BufferInfo *bufferInfo = [bufferIdBufferInfoMap objectForKey:bufferId];
    NetworkId *networkId = [bufferInfo networkId];
    IrcChannel *ircChannel = [[networkIdChannelMapMap objectForKey:networkId] valueForKey:bufferInfo.bufferName];
    return ircChannel.users;
}

@end
