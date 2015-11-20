//
//  XJSplit.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/19/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "XJSplit.h"

@interface XJSplit ()


@end

@implementation XJSplit

- (instancetype) init
{
    self = [super init];

    if(self != nil)
    {
        _number = -1; // invalid
        _distance = 0;
        _duration = 0;
        _altitudeMin = -128;
        _altitudeMin = -128;
        _heartRateAvg = 0;
        _heartRateReceived = 0;
        _lastLocation = nil;
    }

    return self;
}


- (BOOL) loadSplit:(NSDictionary *)dict
{
    id val;
    
    val = [dict objectForKey:@"duration"];
    if((NSNull *)val != [NSNull null])
        self.duration = [val intValue];
    else
        return NO;
    
    val = [dict objectForKey:@"length"];
    if((NSNull *)val != [NSNull null])
        self.distance = [val intValue];
    else
        return NO;
    
    val = [dict objectForKey:@"avgheartrate"];
    if((NSNull *)val != [NSNull null])
        self.heartRateAvg = [val intValue];

    val = [dict objectForKey:@"minaltitude"];
    if((NSNull *)val != [NSNull null])
        self.altitudeMin = [val intValue];
    
    val = [dict objectForKey:@"maxaltitude"];
    if((NSNull *)val != [NSNull null])
        self.altitudeMax = [val intValue];

    return YES;
}
@end
