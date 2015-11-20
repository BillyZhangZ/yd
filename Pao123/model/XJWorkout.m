//
//  KKWorkout.m
//  runhelper
//
//  Created by Zhenyong Chen on 5/19/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//
#import "config.h"
#import "XJWorkout.h"

@implementation XJWorkout

- (instancetype) init:(unsigned int)userID
{
    self = [super init];
    if(self != nil)
    {
        _sessions = [[NSMutableArray alloc] init];
        _lock = [[NSRecursiveLock alloc] init];
        _summary = [[XJWorkoutSummary alloc] init];
        _userID = userID;
        _currentHeartRate = @"0";
    }

    return self;
}

/*
{
    "contenttype":"workouthead",
    "users_id":"guest100",
    "starttime":"2015-06-04 18:23:05", // TODO: add UDID to identify
    "type":"1"
}
 */
- (NSString *) getWorkoutHeader
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;

    tmp = @"workout={\"contenttype\":\"workouthead\",";
    [res appendString:tmp];

    tmp = [NSString stringWithFormat:@"\"users_id\":\"%d\",", self.userID];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"starttime\":\"%@\",", stringFromDate(self.summary.startTime)];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"type\":\"1\""];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"}"];
    [res appendString:tmp];

    return res;
}

/*
{
 "contenttype":"workoutend",
 "users_id":"guest100",
 "starttime":"2015-06-04 18:23:05", // TODO: add UDID to identify
 "duration":"7208",
 "length":"23089",
 "maxheight":"64",
 "minheight":"2",
 "maxpace":"891",
 "minpace":"241"
}
 */
- (NSString *) getWorkoutEnd
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;

    tmp = @"workout={\"contenttype\":\"workoutend\",";
    [res appendString:tmp];

    tmp = [NSString stringWithFormat:@"\"users_id\":\"%d\",", self.userID];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"starttime\":\"%@\",", stringFromDate(self.summary.startTime)];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"duration\":\"%d\",",(int)self.summary.duration];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"length\":\"%d\",", (int)self.summary.length];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"maxheight\":\"%d\",", (unsigned int)self.summary.altitudeUp];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"minheight\":\"%d\",", (unsigned int)self.summary.altitudeDown];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"maxpace\":\"%d\",", (unsigned int)self.summary.maxPace];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"minpace\":\"%d\",", (unsigned int)self.summary.minPace];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"avgpace\":\"%d\",", (unsigned int)self.summary.avgPace];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"calorie\":\"%d\",", (unsigned int)self.summary.calorie];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"minheartrate\":\"%d\",", (unsigned int)self.summary.minHeartRate];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"maxheartrate\":\"%d\",", (unsigned int)self.summary.maxHeartRate];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"avgheartrate\":\"%d\",", (unsigned int)self.summary.avgHeartRate];
    [res appendString:tmp];
    tmp = [self getWorkoutSplits];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"}"];
    [res appendString:tmp];

    return res;
}

- (NSString *) getWorkoutSplits
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;

    tmp = @"\"splits\":[";
    [res appendString:tmp];

    NSUInteger i;
    NSUInteger count = self.summary.splits.count;
    for(i=0; i<count; i++)
    {
        XJSplit *split = [self.summary.splits objectAtIndex:i];
        tmp = @"{";
        [res appendString:tmp];
        tmp = [NSString stringWithFormat:@"\"id\":\"%d\",", (int)split.number];
        [res appendString:tmp];
        tmp = [NSString stringWithFormat:@"\"length\":\"%d\",", (int)split.distance];
        [res appendString:tmp];
        tmp = [NSString stringWithFormat:@"\"duration\":\"%d\",", (int)split.duration];
        [res appendString:tmp];
        tmp = [NSString stringWithFormat:@"\"avgheartrate\":\"%d\",", (int)split.heartRateAvg];
        [res appendString:tmp];
        tmp = [NSString stringWithFormat:@"\"minaltitude\":\"%d\",", (int)split.altitudeMin];
        [res appendString:tmp];
        tmp = [NSString stringWithFormat:@"\"maxaltitude\":\"%d\"", (int)split.altitudeMax];
        [res appendString:tmp];
        if(i == count-1)
            tmp = @"}";
        else
            tmp = @"},";
        [res appendString:tmp];
    }

    tmp = @"]";
    [res appendString:tmp];
    
    return res;
}

- (NSUInteger) calcPace:(NSDate *)atTime
{
    XJSession *lastSession = [self.sessions lastObject];
    if(lastSession == nil)
        return 0;
    CLLocation *lastLoc = lastSession.locations.lastObject;
    if(lastLoc == nil)
        return 0;
    if([atTime timeIntervalSinceDate:lastLoc.timestamp] >= 5)
        return 0;
    return (NSUInteger)lastLoc.speed;
}

- (void) dump
{
    // dump summary first
    [self.summary dump];

    int sessionCount = (int)_sessions.count;
    NSLog(@"Session count: %d\n", sessionCount);

    int i;
    for(i=0; i<sessionCount; i++)
    {
        XJSession *session = [_sessions objectAtIndex:i];
        if(session != nil)
            [session dump];
    }
}
- (NSDictionary *) workoutToDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    
    //[dict setObject:[NSString stringWithFormat:@"%ld",(long)self.dbID] forKey:@"id"];
    [dict setObject:stringFromDate(self.summary.startTime) forKey:@"starttime"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.duration] forKey:@"duration"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.length] forKey:@"length"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.altitudeUp] forKey:@"maxheight"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.altitudeDown] forKey:@"minheight"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.maxPace] forKey:@"maxpace"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.minPace] forKey:@"minpace"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.avgPace] forKey:@"avgpace"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.calorie] forKey:@"calorie"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.minHeartRate] forKey:@"minheartrate"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.maxHeartRate] forKey:@"maxheartrate"];
    [dict setObject:[NSString stringWithFormat:@"%ld",(long)self.summary.avgHeartRate] forKey:@"avgheartrate"];
    NSMutableArray *laps = [[NSMutableArray alloc]init];
    [dict setObject:laps forKey:@"lap"];
    
    for (XJSession *session in self.sessions) {
        NSMutableDictionary *lapDict = [[NSMutableDictionary alloc]init];
        NSMutableArray *heartRateArr = [[NSMutableArray alloc]init];
        NSMutableArray *locationArr = [[NSMutableArray alloc]init];
#pragma mark 数组可能是nil
        [lapDict setObject:heartRateArr forKey:@"heartratedata"];
        [lapDict setObject:locationArr  forKey:@"locationdata"];
        
        [lapDict setObject: [NSString stringWithFormat:@"%ld",(long)session.number] forKey:@"lap"];
        [lapDict setObject: stringFromDate(session.timeStart) forKey:@"starttime"];
        [lapDict setObject: [NSString stringWithFormat:@"%ld",(long)session.length] forKey:@"length"];
        [lapDict setObject: [NSString stringWithFormat:@"%ld",(long)session.duration] forKey:@"duration"];
        
        for (XJHeartRate *heartRate in session.heartRates) {
            NSMutableDictionary *hrItem = [[NSMutableDictionary alloc]init];
            [hrItem setObject:[NSString stringWithFormat:@"%ld",(long)heartRate.rate] forKey:@"bpm"];
            NSInteger timeOffset = [heartRate.timeStamp timeIntervalSinceDate:session.timeStart];
            [hrItem setObject:[NSString stringWithFormat:@"%ld",(long)timeOffset] forKey:@"timeoffset"];
            [heartRateArr addObject:hrItem];
        }
        
        for (CLLocation *loc in session.locations) {
            NSMutableDictionary *locItem = [[NSMutableDictionary alloc]init];
            [locItem setObject:[NSString stringWithFormat:@"%f",loc.altitude] forKey:@"altitude"];
            [locItem setObject:[NSString stringWithFormat:@"%f",loc.coordinate.latitude] forKey:@"latitude"];
            [locItem setObject:[NSString stringWithFormat:@"%f",loc.coordinate.longitude] forKey:@"longitude"];
            [locItem setObject:[NSString stringWithFormat:@"%f",loc.horizontalAccuracy] forKey:@"haccuracy"];
            [locItem setObject:[NSString stringWithFormat:@"%f",loc.verticalAccuracy] forKey:@"vaccuracy"];
            [locItem setObject:[NSString stringWithFormat:@"%ld",(long)loc.speed] forKey:@"speed"];
            NSInteger timeOffset = [loc.timestamp timeIntervalSinceDate:session.timeStart];
            [locItem setObject:[NSString stringWithFormat:@"%ld",(long)timeOffset] forKey:@"timeoffset"];
            [locationArr addObject:locItem];
        }
        
    }
    
    return dict;
}


@end
