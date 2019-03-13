// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "IrcChannel.h"

@implementation IrcChannel

@synthesize name, topic, users;

- (id) initWithName:(NSString*)n
{
    self = [super init];
    self.name = n;
    self.users = [NSMutableArray array];
    return self;
}

- (void) addUser:(IrcUser*)u
{
    NSUInteger newIndex = [self.users indexOfObject:u
                                inSortedRange:(NSRange){0, [self.users count]}
                                      options:NSBinarySearchingInsertionIndex
                                    usingComparator:^(id o1, id o2) {
                                        IrcUser *u1 = o1;
                                        IrcUser *u2 = o2;
                                        return [u1.nick compare:u2.nick options:NSCaseInsensitiveSearch];
                                    }];

    [self.users insertObject:u atIndex:newIndex];
}

- (void) partUser:(IrcUser*)u
{
    [self.users removeObject:u];
}

- (NSString *) description {
    NSMutableString *ret = [[NSMutableString alloc] init];
    [ret appendFormat:@"IrcChannel %@ [", self.name];
    for (NSString *u in self.users) {
        [ret appendFormat:@"%@ ", u];
    }
    [ret appendFormat:@"]"];

    return ret;
}

@end
