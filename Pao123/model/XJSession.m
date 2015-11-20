//
//  KKSession.m
//  runhelper
//
//  Created by Zhenyong Chen on 5/18/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJSession.h"
#import "XJWorkout.h"
#import "XJSplit.h"

@implementation XJHeartRate
@end

@interface XJSession ()
{
    XJWorkoutSummary *_summary;
}

@end

@implementation XJSession

- (instancetype) init:(NSUInteger)number
{
    self = [super init];

    if(self != nil)
    {
        // session is started when it is created
        _length = 0;
        _timeStart = [NSDate date];
        _timeEnd = nil;
        _number = number;
        _locations = [[NSMutableArray alloc] init];
        _heartRates = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (BOOL) isOpen
{
    if(self.timeEnd == NULL)
        return YES;
    else
        return NO;
}

- (void) start:(id)workout
{
    // update summary
    if(workout != nil)
    {
        XJWorkout *wo = workout;
        [wo.summary onSessionBegin:self];
    }
}

- (void) finish:(id)workout
{
    if([self isOpen] == NO)
        return;

    self.timeEnd = [NSDate date];

    // update summary if required
    if(workout != nil)
    {
        XJWorkout *wo = workout;
        [wo.summary onSessionFinished:self];
    }
}

- (BOOL) appendLocation:(CLLocation *)loc ofworkout:(id)workout
{
    // this session must be an open session
    if([self isOpen] == NO)
        return NO;

    // timestamp check
    CLLocation *lastLoc = self.locations.lastObject;
    if(lastLoc != nil)
    {
        if([lastLoc.timestamp compare:loc.timestamp] != NSOrderedAscending)
            return NO;

        // accumulate distance
        CLLocationDistance distance = [loc distanceFromLocation:lastLoc];
        self.length += distance;
    }

    // calculate pace
    CLLocation *locNew = [[CLLocation alloc] initWithCoordinate:loc.coordinate altitude:loc.altitude horizontalAccuracy:loc.horizontalAccuracy verticalAccuracy:loc.verticalAccuracy course:loc.course speed:[self calcRealTimePace:loc] timestamp:loc.timestamp];

    [self.locations addObject:locNew];

    // update summary
    if(workout != nil)
    {
        XJWorkout *wo = workout;
        [wo.summary onLocationAdded:locNew workout:workout session:self];
    }

    return YES;
}

- (BOOL) appendHeartRate:(NSUInteger)heartRate at:(NSDate *)timeStamp ofworkout:(id)workout
{
    // this session must be an open session
    if([self isOpen] == NO)
        return NO;

    // timestamp check
    XJHeartRate *last = self.heartRates.lastObject;
    if(last != nil)
    {
        if([last.timeStamp compare:timeStamp] != NSOrderedAscending)
            return NO;
    }

    // do not record invalid value
    if(heartRate != 0)
    {
        XJHeartRate *hr = [[XJHeartRate alloc] init];
        hr.timeStamp = timeStamp;
        hr.rate = heartRate;

        [self.heartRates addObject:hr];
    }

    // update summary
    if(workout != nil)
    {
        XJWorkout *wo = workout;
        [wo.summary onHeartRateAdded:heartRate workout:wo session:self];
    }

    return YES;
}

// TODO: optimize it when session count is too big
- (NSTimeInterval) duration
{
    NSTimeInterval intval;

    if([self isOpen] == YES)
    {
        NSDate *curTime = [NSDate date];
        intval = [curTime timeIntervalSinceDate:_timeStart];
    }
    else
    {
        intval = [_timeEnd timeIntervalSinceDate:_timeStart];
    }

    return intval;
}

#define MAXPACE (59*60+59)
#define PACE_SLIDE_WINDOW 15 // 15 seconds average
#define PACE_EASE_WINDOW 3
#define PACE_FALL_RATE 700 // 500-second per second

// calculate length from location i to j
- (NSUInteger) calcLengthFromLocationIndex:(NSUInteger)i toIndex:(NSUInteger)j
{
    NSUInteger length = 0;
    CLLocation *loc1 = [_locations objectAtIndex:i];

    for(i=i+1; i<=j; i++)
    {
        CLLocation *loc2 = [_locations objectAtIndex:i];
        CLLocationDistance distance = [loc2 distanceFromLocation:loc1];
        length += distance;
        loc1 = loc2;
    }
    
    return length;
}

// algorithm:
// back PACE_SLIDE_WINDOW  seconds  from latest location
// calculate the average pace of that window
// the average pace keep for PACE_EASE_WINDOW seconds, and then
// fall down at rate of PACE_FALL_RATE
- (NSUInteger) calcRealTimePace:(CLLocation *)newLocation
{
    NSInteger i;
    NSInteger count = _locations.count;
    
    for(i=count-1; i>=0; i--)
    {
        CLLocation *loc = [_locations objectAtIndex:i];
        NSTimeInterval ti = [newLocation.timestamp timeIntervalSinceDate:loc.timestamp];
        if(ti >= PACE_SLIDE_WINDOW || i == 0)
        {
            // window size is enough
            // calculate length
            NSUInteger length = [self calcLengthFromLocationIndex:i toIndex:count-1];
            if(length > 0)
            {
                NSUInteger pace = 1000 * ti / length;
                if(pace > MAXPACE)
                    pace = 0;
                
                return pace;
            }
            else
            {
                return 0;
            }
        }
    }
    return 0;
    
}

- (NSString *)locationDataToString:(NSUInteger)fromIndex count:(NSUInteger)count
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;

    NSUInteger i;
    for(i=fromIndex; i<fromIndex+count; i++)
    {
        CLLocation *loc = [_locations objectAtIndex:i];
        NSTimeInterval intval = [loc.timestamp timeIntervalSinceDate:_timeStart];
        tmp = [NSString stringWithFormat:@"{\"timeoffset\":\"%d\",\"latitude\":\"%f\",\"longitude\":\"%f\",\"altitude\":\"%f\",\"haccuracy\":\"%f\",\"vaccuracy\":\"%f\",\"speed\":\"%d\"}",(int)intval,loc.coordinate.latitude,loc.coordinate.longitude,loc.altitude,loc.horizontalAccuracy,loc.verticalAccuracy,(int)loc.speed]; // speed is set by app to record instant pace instead
        [res appendString:tmp];
        if(i < fromIndex+count-1)
            [res appendString:@","];
    }

    return res;
}

- (NSString *)heartRateDataToString:(NSUInteger)fromIndex count:(NSUInteger)count
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;

    NSUInteger i;
    for(i=fromIndex; i<fromIndex+count; i++)
    {
        XJHeartRate *rate = [_heartRates objectAtIndex:i];
        NSTimeInterval intval = [rate.timeStamp timeIntervalSinceDate:_timeStart];
        tmp = [NSString stringWithFormat:@"{\"timeoffset\":\"%d\",\"bpm\":\"%d\"}",(int)intval,(unsigned int)rate.rate];
        [res appendString:tmp];
        if(i < fromIndex+count-1)
            [res appendString:@","];
    }
    
    return res;
}

/*
{
    "contenttype":"sessionhead",
    "users_id":"guest100",
    "starttime":"2015-06-04 18:23:05", // TODO: add UDID to identify
    "lap":[{
    "lap":"1", // session number in this workout
    "starttime":"2015-06-04 18:31:08"
    }]
}
 */
- (NSString *) getSessionHeader:(XJWorkout *)wo
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;
    
    tmp = @"workout={\"contenttype\":\"sessionhead\",";
    [res appendString:tmp];

    tmp = [NSString stringWithFormat:@"\"users_id\":\"%d\",", wo.userID];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"starttime\":\"%@\",", stringFromDate(wo.summary.startTime)];
    [res appendString:tmp];

    tmp = [NSString stringWithFormat:@"\"lap\":[{"];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"starttime\":\"%@\",", stringFromDate(self.timeStart)];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"lap\":\"%d\"", (int)self.number];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"}]}"];
    [res appendString:tmp];

    return res;
}

/*
 {
 "contenttype":"sessionend",
 "users_id":"guest100",
 "starttime":"2015-06-04 18:23:05", // TODO: add UDID to identify
 "lap":"1", // session number in this workout
 "duration":"3580",
 "length":"10800"
 }
 */
- (NSString *) getSessionEnd:(XJWorkout *)wo
{
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;

    tmp = @"workout={\"contenttype\":\"sessionend\",";
    [res appendString:tmp];

    tmp = [NSString stringWithFormat:@"\"users_id\":\"%d\",", wo.userID];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"starttime\":\"%@\",", stringFromDate(wo.summary.startTime)];
    [res appendString:tmp];

    tmp = [NSString stringWithFormat:@"\"lap\":[{"];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"starttime\":\"%@\",", stringFromDate(self.timeStart)];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"lap\":\"%d\",", (int)self.number];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"duration\":\"%d\",", (int)self.duration];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"length\":\"%d\"", (int)self.length];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"}]}"];
    [res appendString:tmp];

    return res;
}

/*
 {
 "contenttype":"sessiondata",
 "users_id":"guest100",
 "starttime":"2015-06-04 18:23:05", // TODO: add UDID to identify
 "lap":"1", // session number in this workout
 "locationdata":[{"timeoffset":"2","latitude":"133.29333","longitude":"22.87634","altitude":"3.8","haccuracy":"8.76","vaccuracy":"1.5"},...],
 "heartratedata":[{"timeoffset":"3","bpm":"76"},...]
 }
 */
- (NSString *) getSessionData:(id)workout range:(NSUInteger *)range
{
    XJWorkout *wo = workout;
    NSMutableString *res = [[NSMutableString alloc] initWithString:@""];
    NSString *tmp;

    tmp = @"workout={\"contenttype\":\"sessiondata\",";
    [res appendString:tmp];

    tmp = [NSString stringWithFormat:@"\"users_id\":\"%d\",", wo.userID];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"starttime\":\"%@\",", stringFromDate(wo.summary.startTime)];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"length\":\"%d\",", (unsigned int)wo.summary.length];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"duration\":\"%d\",", (unsigned int)wo.summary.duration];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"calorie\":\"%d\",", (unsigned int)wo.summary.calorie];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"minpace\":\"%d\",",(unsigned int)wo.summary.minPace];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"maxpace\":\"%d\",",(unsigned int)wo.summary.maxPace];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"maxheight\":\"%d\",",(unsigned int)wo.summary.altitudeUp];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"minheight\":\"%d\",",(unsigned int)wo.summary.altitudeDown];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"lap\":[{"];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@"\"lap\":\"%d\"", (int)self.number];
    [res appendString:tmp];
    tmp = [NSString stringWithFormat:@",\"starttime\":\"%@\"", stringFromDate(self.timeStart)];
    [res appendString:tmp];

    NSUInteger locIndex = range[0];
    NSUInteger locCount = range[1];
    NSUInteger heartRateIndex = range[2];
    NSUInteger heartRateCount = range[3];

    NSAssert(locCount <= _locations.count, @"Bad location count");
    NSAssert(heartRateCount <= _heartRates.count, @"Bad heart rate count");

    // send [locIndex, locCount)
    if(locIndex < locCount)
    {
        tmp = @",\"locationdata\":[";
        [res appendString:tmp];
        tmp = [self locationDataToString:locIndex count:locCount-locIndex];
        [res appendString:tmp];
        tmp = @"]";
        [res appendString:tmp];
    }

    // send [_heartRateIndicator, rateCount)
    if(heartRateIndex < heartRateCount)
    {
        tmp = @",\"heartratedata\":[";
        [res appendString:tmp];
        tmp = [self heartRateDataToString:heartRateIndex count:heartRateCount-heartRateIndex];
        [res appendString:tmp];
        tmp = @"]";
        [res appendString:tmp];
    }
    
    // send splits?

    tmp = [NSString stringWithFormat:@"}]}"];
    [res appendString:tmp];

    return res;
}

- (BOOL) loadSession:(NSDictionary *)dict realTime:(BOOL)realtime workout:(id)wo
{
    id val;
    
    val = getDateFromDictionary(dict, @"starttime");
    if((NSNull *)val == [NSNull null])
        return NO;

    self.timeStart = val;

    if(realtime == NO)
    {
        val = [dict objectForKey:@"duration"];
        if((NSNull *)val != [NSNull null])
            self.timeEnd = [NSDate dateWithTimeInterval:[val intValue] sinceDate:self.timeStart];
    }

    val = [dict objectForKey:@"length"];
    if((NSNull *)val != [NSNull null])
        _length = [val intValue];

    // load location data array
    val = [dict objectForKey:@"locationdata"];
    if((NSNull *)val != [NSNull null])
        if([self loadLocationData:val] == NO)
            return NO;

    // load heart rate data array
    val = [dict objectForKey:@"heartratedata"];
    if((NSNull *)val != [NSNull null])
        if([self loadHeartRateData:val workout:wo] == NO)
            return NO;
    
    return YES;
}

- (BOOL) loadLocationData:(NSArray *)arr
{
    int i;
    id val;

    for(i=0; i<arr.count; i++)
    {
        NSDictionary *item = [arr objectAtIndex:i];
        if(item == nil)
            continue;

        val = [item objectForKey:@"timeoffset"];
        if((NSNull *)val == [NSNull null])
            return NO;
        NSDate *tm = [NSDate dateWithTimeInterval:[val intValue] sinceDate:self.timeStart];
        
        val = [item objectForKey:@"latitude"];
        if((NSNull *)val == [NSNull null])
            return NO;
        CLLocationDegrees lat = [val doubleValue];

        val = [item objectForKey:@"longitude"];
        if((NSNull *)val == [NSNull null])
            return NO;
        CLLocationDegrees lon = [val doubleValue];

        CLLocationCoordinate2D coord;
        coord.latitude = lat;
        coord.longitude = lon;
        
        val = [item objectForKey:@"altitude"];
        if((NSNull *)val == [NSNull null])
            return NO;
        CLLocationDistance alt = [val doubleValue];
        
        val = [item objectForKey:@"haccuracy"];
        if((NSNull *)val == [NSNull null])
            return NO;
        CLLocationAccuracy haccu = [val doubleValue];
        
        val = [item objectForKey:@"vaccuracy"];
        if((NSNull *)val == [NSNull null])
            return NO;
        CLLocationAccuracy vaccu = [val doubleValue];
        
        val = [item objectForKey:@"speed"];
        NSUInteger pace = 0;
        if((NSNull *)val != [NSNull null])
            pace = [val integerValue];

        CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coord altitude:alt horizontalAccuracy:haccu verticalAccuracy:vaccu course:0 speed:pace timestamp:tm];

        [self.locations addObject:loc];
    }

    return YES;
}

- (BOOL) loadHeartRateData:(NSArray *)arr workout:(XJWorkout *)wo
{
    id val;
    int i;
    for(i=0; i<arr.count; i++)
    {
        NSDictionary *item = [arr objectAtIndex:i];
        if(item != nil)
        {
            val = [item objectForKey:@"timeoffset"];
            if((NSNull *)val == [NSNull null])
                return NO;
            NSDate *tm = [NSDate dateWithTimeInterval:[val intValue] sinceDate:self.timeStart];

            val = [item objectForKey:@"bpm"];
            if((NSNull *)val == [NSNull null])
                return NO;
            NSUInteger rate = [val intValue];

            XJHeartRate *hr = [[XJHeartRate alloc] init];
            hr.timeStamp = tm;
            hr.rate = rate;
            [self.heartRates addObject:hr];
            
            if(i == arr.count - 1)
            {
                wo.currentHeartRate = [NSString stringWithFormat:@"%d",(int)hr.rate];
            }
        }
    }

    return YES;
}

- (void) dump
{
    NSLog(@"Total locations: %d", (int)self.locations.count);
}

@end
