// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import <Foundation/Foundation.h>

#import "SignedId.h"

@interface AppState : NSObject


+ (void) setLastSelectedBufferId:(BufferId *)lastSelectedBufferId;
+ (BufferId*) getLastSelectedBufferId;

@end
