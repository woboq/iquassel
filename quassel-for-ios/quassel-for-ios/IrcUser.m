// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "IrcUser.h"
#import "QuasselUtils.h"


@implementation IrcUser

@synthesize nick, realName, away;

- (id) initWithUhost:(NSString*)uhost
{
    self = [super init];
    self.nick = [QuasselUtils extractNick:uhost];
    return self;
}

- (NSString*) description {
    return self.nick;
}

@end
