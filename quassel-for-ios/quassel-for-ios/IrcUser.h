// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>

@interface IrcUser : NSObject

- (id) initWithUhost:(NSString*)uhost;
- (NSString*) description;

@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *realName;
@property (nonatomic) BOOL away;


@end
