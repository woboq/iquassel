//
//  QuasselTests.m
//  QuasselTests
//
//  Created by M G on 23.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuasselTests.h"
#import "QVariant.h"

@implementation QuasselTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testStringVariant
{
    //STFail(@"Unit tests are not implemented yet in QuasselTests");
    
   // STAssertEqualsWithAccuracy(<#a1#>, <#a2#>, <#accuracy...#><#a1, a2...#>)
    QVariant *variant = [[QVariant alloc] initWithString:@"ABC"];
    NSData *data = [NSData dataWithBytes:"\x00\x00\x00\x0a\x00\x00\x00\x00\x06\x00\x41\x00\x42\x00\x43" length:15];
    //STAssertEquals(data, [variant serialize], @"QVariant integer serialization");
    NSLog(@"%@", [variant serialize]);
    NSLog(@"%@", data);

    STAssertTrue([[variant serialize] isEqualToData:data], @"QVariant string serialization");
    
}


- (void)testIntVariant
{    
    QVariant* variant = [[QVariant alloc] initWithInteger:[NSNumber numberWithInt:123]];
    NSData* data = [NSData dataWithBytes:"\x00\x00\x00\x02\x00\x00\x00\x00\x7b" length:9];
    STAssertTrue([[variant serialize] isEqualToData:data], @"QVariant integer serialization");

    NSLog(@"%@", [variant serialize]);
    NSLog(@"%@", data);
}

@end
