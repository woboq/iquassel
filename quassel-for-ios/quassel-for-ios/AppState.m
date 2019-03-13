// Dual-Licensed, GPLv3 and Woboq GmbH's private license. See file "LICENSE"

#import "AppState.h"

@implementation AppState

+ (NSUserDefaults*) preferences
{
    return [NSUserDefaults standardUserDefaults];
}

+ (BufferId*) getLastSelectedBufferId
{
    NSUserDefaults *prefs = [AppState preferences];
    int value = [prefs integerForKey:@"lastSelectedBufferId"];
    return [[BufferId alloc] initWithInt:value];
}

+ (void) setLastSelectedBufferId:(BufferId *)lastSelectedBufferId
{
    NSUserDefaults *prefs = [AppState preferences];
    [prefs setInteger:lastSelectedBufferId.intValue forKey:@"lastSelectedBufferId"];
    [prefs synchronize];
}


@end
