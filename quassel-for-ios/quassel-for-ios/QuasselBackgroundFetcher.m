//
//  QuasselBackgroundFetcher.m
//  quassel-for-ios
//
//  Created by Markus Goetz on 17.04.20.
//

#import "QuasselBackgroundFetcher.h"

@interface QuasselBackgroundFetcher ()
@property (strong, nonatomic) QuasselCoreConnection *quasselCoreConnection;
@property (strong, nonatomic) void (^fetchCompletionHandler)(UIBackgroundFetchResult r);

@end

@implementation QuasselBackgroundFetcher
{
}

- (id) initWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    self = [super init];

    self.fetchCompletionHandler = completionHandler;

    self.quasselCoreConnection = [[QuasselCoreConnection alloc] init];
    self.quasselCoreConnection.delegate = self;

    return self;
}

- (void) connectTo:(NSString*)hostName port:(int)port userName:(NSString*)userName passWord:(NSString*)passWord
{
    [self.quasselCoreConnection connectTo:hostName port:port userName:userName passWord:passWord];
}

- (void)quasselAllNetworkInitReceived {
    NSLog(@"quasselAllNetworkInitReceived");
}

- (void)quasselAuthenticated {
    NSLog(@"quasselAuthenticated");
}

- (void)quasselBufferListReceived {
    NSLog(@"quasselBufferListReceived");
}

- (void)quasselBufferListUpdated {
    NSLog(@"quasselBufferListUpdated");
}

- (void)quasselConnected {
    NSLog(@"quasselConnected");
}

- (void)quasselEncrypted {
    NSLog(@"quasselEncrypted");
}

- (void)quasselLastSeenMsgUpdated:(MsgId *)messageId forBuffer:(BufferId *)bufferId {

}

- (void)quasselMessageReceived:(Message *)msg received:(enum ReceiveStyle)style onIndex:(int)i {

}

- (void)quasselMessagesReceived:(NSArray *)messages received:(enum ReceiveStyle)style {

}

- (void)quasselNetworkInitReceived:(NSString *)networkName {

}

- (void)quasselNetworkNameUpdated:(NetworkId *)networkId {

}

- (void)quasselSocketDidDisconnect:(NSString *)msg {
    if (self.fetchCompletionHandler) {
        self.fetchCompletionHandler(UIBackgroundFetchResultFailed);
    }
}

- (void)quasselSocketFailedConnect:(NSString *)msg {
    self.fetchCompletionHandler(UIBackgroundFetchResultFailed);
    self.fetchCompletionHandler = nil;
}

- (void)quasselSwitchToBuffer:(BufferId *)bufferId {
    
}

- (void) quasselFullyConnected {
    NSLog(@"Fully connected");
    int unreadCount = [self.quasselCoreConnection computeUnreadCountForAllBuffers];// computeRelevantUnreadCount
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount]; // FIXME only relevant buffers
    NSLog(@"%d", unreadCount);
    if (unreadCount > 0) {
        self.fetchCompletionHandler(UIBackgroundFetchResultNewData);
        self.fetchCompletionHandler = nil;
    } else {
        self.fetchCompletionHandler(UIBackgroundFetchResultNoData);
        self.fetchCompletionHandler = nil;
    }
    
}
@end
