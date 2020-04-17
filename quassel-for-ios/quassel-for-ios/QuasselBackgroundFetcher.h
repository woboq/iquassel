//
//  QuasselBackgroundFetcher.h
//  quassel-for-ios
//
//  Created by Markus Goetz on 17.04.20.
//

#import <Foundation/Foundation.h>
#import "QuasselCoreConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface QuasselBackgroundFetcher : NSObject <QuasselCoreConnectionDelegate>

- (id) initWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void) connectTo:(NSString*)hostName port:(int)port userName:(NSString*)userName passWord:(NSString*)passWord;

@end

NS_ASSUME_NONNULL_END
