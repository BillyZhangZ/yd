//
//  XJWorkoutSummary.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/19/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJWorkoutSummary.h"
#import "XJSession.h"

@interface XJWorkoutSummary ()
{
    NSUInteger _lastMileStone; // last time the distance is broadcast to user via voice
    NSUInteger _heartRateCount;
}
@end

@implementation XJWorkoutSummary

- (instancetype) init
{
    self = [super init];
    
    if(self != nil)
    {
        _startTime = [NSDate date];
        _length = 0;
        _duration = 0;
        _calorie = 0;
        _avgPace = 0;
        _minPace = 0;
        _maxPace = 0;
        _altitudeUp = 0;
        _altitudeDown = 0;
        _avgHeartRate = 0;
        _minHeartRate = 0;
        _maxHeartRate = 0;
        _lastMileStone = 0;
        _splits = [[NSMutableArray alloc] init];
        _heartRateCount = 0;
        _userWeight = 70;
        _currentGpsStrength = -1;
    }
    
    return self;
}

- (void) onSessionBegin:(XJSession *)session
{
    XJSplit *split;

    if(self.splits.count == 0)
    {
        split = [[XJSplit alloc] init];
        split.number = 0;
        [self.splits addObject:split];
    }
    else
    {
        split = self.splits.lastObject;
    }

    // record begin time
    split.beginTime = session.timeStart;
    split.lastLocation = nil;
}

- (void) onSessionFinished:(XJSession *)session
{
    // accumulate time interval
    XJSplit *split = self.splits.lastObject;
    split.duration += [session.timeEnd timeIntervalSinceDate:split.beginTime];
    split.beginTime = session.timeEnd;
    split.lastLocation = nil;
}

- (void) onLocationAdded:(CLLocation *)newLocation workout:(id)workout session:(id)session
{
    // update pace
    if(newLocation.speed < self.minPace)
        self.minPace = newLocation.speed;
    if(newLocation.speed > self.maxPace)
        self.maxPace = newLocation.speed;

    // update altitude
    if(self.altitudeUp == self.altitudeDown == 0)
    {
        self.altitudeDown = self.altitudeUp = newLocation.altitude;
    }
    else
    {
        if(self.altitudeUp < newLocation.altitude)
            self.altitudeUp = newLocation.altitude;
        if(self.altitudeDown > newLocation.altitude)
            self.altitudeDown = newLocation.altitude;
    }

    XJSplit *split = self.splits.lastObject;
    if(split == nil)
        return;

    if(split.startLocation == nil)
    {
        split.duration += [newLocation.timestamp timeIntervalSinceDate:split.beginTime];
        split.beginTime = newLocation.timestamp;
        split.lastLocation = newLocation;
        split.altitudeMin = newLocation.altitude;
        split.altitudeMax = newLocation.altitude;
        split.startLocation = newLocation;
    }
    else
    {
        CLLocation *cachedStart = split.lastLocation;
        CLLocationDistance sampleLength = [newLocation distanceFromLocation:cachedStart];
        CLLocationDistance origSampleLength = sampleLength;
        NSTimeInterval sampleDuration = [newLocation.timestamp timeIntervalSinceDate:split.lastLocation.timestamp];
        double percent = (double)(1000 - split.distance) / origSampleLength;

        if(split.altitudeMin > newLocation.altitude)
            split.altitudeMin = newLocation.altitude;
        if(split.altitudeMax < newLocation.altitude)
            split.altitudeMax = newLocation.altitude;

        if(split.distance + sampleLength < 1000)
        {
            split.distance += sampleLength;
            split.duration += sampleDuration;
        }
        else
        {
            // cut (1000 - split.distance) and get the remain
            sampleLength -= (1000 - split.distance);

            split.distance = 1000;
            split.duration += origSampleLength * percent;

            // create next splits
            do
            {
                // tempLocation: insert a fake location at (origSampleLength - sampleLength). This fake location is the end point of this split and start point of next split
                percent = (double)(origSampleLength - sampleLength) / origSampleLength;
                CLLocationDegrees lon = cachedStart.coordinate.longitude + (newLocation.coordinate.longitude - cachedStart.coordinate.longitude) * percent;
                CLLocationDegrees lat = cachedStart.coordinate.latitude + (newLocation.coordinate.latitude - cachedStart.coordinate.latitude) * percent;
                CLLocationDistance alt = cachedStart.altitude + (newLocation.altitude - cachedStart.altitude) * percent;
                CLLocationAccuracy hacc = cachedStart.horizontalAccuracy;
                CLLocationAccuracy vacc = cachedStart.verticalAccuracy;
                CLLocationSpeed speed = cachedStart.speed;
                NSTimeInterval interval = sampleDuration * percent;
                NSDate *ts = [[NSDate alloc] initWithTimeInterval:interval sinceDate:cachedStart.timestamp];
                CLLocation *tempLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon) altitude:alt horizontalAccuracy:hacc verticalAccuracy:vacc course:0 speed:speed timestamp:ts];
                
                split.endLocation = tempLocation;
                split.lastLocation = nil;

                XJSplit *nextSplit = [[XJSplit alloc] init];
                nextSplit.startLocation = tempLocation;
                nextSplit.number = split.number + 1;
                nextSplit.distance = (sampleLength >= 1000 ? 1000 : sampleLength);
                if(sampleLength > 0)
                    nextSplit.duration = (double)nextSplit.distance / origSampleLength * sampleDuration;
                nextSplit.altitudeMin = newLocation.altitude;
                nextSplit.altitudeMax = newLocation.altitude;
                [self.splits addObject:nextSplit];
                split = nextSplit;

                sampleLength -= 1000;
            } while(sampleLength >= 0);
        }
        split.lastLocation = newLocation;
        split.endLocation = newLocation;

        // update total length
        self.length += origSampleLength;

        // update calorie
        self.calorie = 1.036 * self.userWeight * self.length / 1000;
        
        // TODO: move to coach thread
        // FIXME!
        #define INTERVAL 500
        NSUInteger nextMileStone = _lastMileStone + INTERVAL;
        NSUInteger thisMileStone = (NSUInteger)self.length / INTERVAL * INTERVAL;
        if(thisMileStone >= nextMileStone)
        {
            NSString *reportMeters = [NSString stringWithFormat:@"1 2 3:%.1f 公里", (double)thisMileStone/1000];
            NSLog(@"current %d meters", (int)self.length);
            say(reportMeters);
            _lastMileStone = thisMileStone;
        }
    }
}

- (void) onHeartRateAdded:(NSUInteger)heartRate workout:(id)workout session:(id)session
{
    // invalid value
    if(heartRate == 0)
        return;

    // calculate min/max/avg
    if(self.minHeartRate == 0 && self.maxHeartRate == 0)
    {
        self.avgHeartRate = self.minHeartRate = self.maxHeartRate = heartRate;
        _heartRateCount++;
    }
    else
    {
        self.avgHeartRate = (self.avgHeartRate * _heartRateCount + heartRate) / (_heartRateCount + 1);
        _heartRateCount++;

        if(heartRate < self.minHeartRate)
            self.minHeartRate = heartRate;
        if(heartRate > self.maxHeartRate)
            self.maxHeartRate = heartRate;
    }

    // update current split
    XJSplit *lastSplit = self.splits.lastObject;
    if(lastSplit != nil)
    {
        lastSplit.heartRateAvg = (lastSplit.heartRateReceived * lastSplit.heartRateAvg + heartRate) / (lastSplit.heartRateReceived + 1);
        lastSplit.heartRateReceived++;
    }
}

- (void) buildSummary:(id) stdWorkout
{
    // calculate pace
    if(self.length > 0)
        self.avgPace = 1000 * self.duration / self.length;
    else
        self.avgPace = 0;
}

- (XJSplit *) getOrCreateSplit:(NSUInteger)splitID
{
    NSUInteger i;
    for(i=0; i<self.splits.count; i++)
    {
        XJSplit *split = [self.splits objectAtIndex:i];
        if(split.number == splitID)
            return split;
    }

    XJSplit *split = [[XJSplit alloc] init];
    split.number = splitID;
    [self.splits addObject:split];
    return split;
}

- (void) dump
{
}

@end
