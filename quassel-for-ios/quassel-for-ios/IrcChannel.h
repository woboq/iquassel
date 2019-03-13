// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>
#import "IrcUser.h"

@interface IrcChannel : NSObject

- (id) initWithName:(NSString *)n;
- (void) addUser:(IrcUser*)u;
- (void) partUser:(IrcUser*)u;
- (NSString *) description;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSMutableArray *users;

@end
