//
//  XJRemoteWorkout.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/18/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJRemoteWorkout.h"

@implementation XJRemoteWorkout

- (instancetype) init:(unsigned int)userID
{
    self = [super init:userID];
    if(self != nil)
    {
        _dbID = -1;
        _downloadState = XJDOWNLOAD_NOTSTARTED;
    }

    return self;
}

- (BOOL) loadWorkout:(NSDictionary *)dict realTime:(BOOL)realtime
{
    id val;

    // check ID
    val = [dict objectForKey:@"id"];
    if((NSNull *)val != [NSNull null])
    {
        self.dbID = [val intValue];
    }

    val = getDateFromDictionary(dict, @"starttime");
    if((NSNull *)val == [NSNull null])
        return NO;
    self.summary.startTime = val;

    val = [dict objectForKey:@"duration"];
    if((NSNull *)val != [NSNull null])
        self.summary.duration = [val intValue];

    val = [dict objectForKey:@"length"];
    if((NSNull *)val != [NSNull null])
        self.summary.length = [val intValue];
    
    val = [dict objectForKey:@"maxheight"];
    if((NSNull *)val != [NSNull null])
        self.summary.altitudeUp = [val intValue];

    val = [dict objectForKey:@"minheight"];
    if((NSNull *)val != [NSNull null])
        self.summary.altitudeDown = [val intValue];

    val = [dict objectForKey:@"maxpace"];
    if((NSNull *)val != [NSNull null])
        self.summary.maxPace = [val intValue];

    val = [dict objectForKey:@"minpace"];
    if((NSNull *)val != [NSNull null])
        self.summary.minPace = [val intValue];

    val = [dict objectForKey:@"avgpace"];
    if((NSNull *)val != [NSNull null])
        self.summary.avgPace = [val intValue];

    val = [dict objectForKey:@"calorie"];
    if((NSNull *)val != [NSNull null])
        self.summary.calorie = [val intValue];

    val = [dict objectForKey:@"minheartrate"];
    if((NSNull *)val != [NSNull null])
        self.summary.minHeartRate = [val intValue];

    val = [dict objectForKey:@"maxheartrate"];
    if((NSNull *)val != [NSNull null])
        self.summary.maxHeartRate = [val intValue];

    val = [dict objectForKey:@"avgheartrate"];
    if((NSNull *)val != [NSNull null])
        self.summary.avgHeartRate = [val intValue];

    val = [dict objectForKey:@"lap"];
    // val is NSArray of sessions
    if((NSNull *)val != [NSNull null])
    {
        NSArray *arr = (NSArray *)val;
        int i;
        for(i=0; i<arr.count; i++)
        {
            NSDictionary *sessionDict = [arr objectAtIndex:i];
            // find lap id
            val = [sessionDict objectForKey:@"lap"];
            if((NSNull *)val == [NSNull null])
                return NO;
            int lapID = [val intValue];
            
            XJSession *session = [self getOrCreateSession:lapID];
            NSAssert(session != nil, @"Failed to create a session");
            if([session loadSession:sessionDict realTime:realtime workout:self] == NO)
            {
                return NO;
            }
        }
    }

    // load splits
    val = [dict objectForKey:@"splits"];
    if((NSNull *)val != [NSNull null])
    {
        NSArray *arr = (NSArray *)val;
        int i;
        for(i=0; i<arr.count; i++)
        {
            NSDictionary *splitDict = [arr objectAtIndex:i];
            // find split id
            val = [splitDict objectForKey:@"id"];
            if((NSNull *)val == [NSNull null])
                return NO;
            int splitID = [val intValue];

            XJSplit *split = [self.summary getOrCreateSplit:splitID];
            if([split loadSplit:splitDict] == NO)
            {
                return NO;
            }
        }
    }

    return YES;
}


- (XJSession *) getOrCreateSession:(NSUInteger)sessionID
{
    NSArray *sessions = self.sessions;
    NSUInteger count = sessions.count;
    NSUInteger i;
    for(i=0; i<count; i++)
    {
        XJSession *session = [sessions objectAtIndex:i];
        if(session.number == sessionID)
            return session;
    }

    XJSession *session = [[XJSession alloc] init:sessionID];
    session.number = sessionID;
    // close last session, but do not update summarry
    [self.sessions.lastObject finish:nil];
    // append this session
    [self.sessions addObject:session];
    return session;
}


@end
