//
//  XJWorkoutSummary.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/19/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "XJSplit.h"


@interface XJWorkoutSummary : NSObject

// total distance in meter
@property (nonatomic) CLLocationDistance length;
// total duration in second
@property (nonatomic) NSTimeInterval duration;
// total calorie
@property (nonatomic) NSUInteger calorie;
// average pace
@property (nonatomic) NSUInteger avgPace;
// min pace
@property (nonatomic) NSUInteger minPace;
// max pace
@property (nonatomic) NSUInteger maxPace;
// altitude up
@property (nonatomic) NSUInteger altitudeUp;
// altitude down
@property (nonatomic) NSUInteger altitudeDown;
// average heart rate
@property (nonatomic) NSUInteger avgHeartRate;
// max heart rate
@property (nonatomic) NSUInteger maxHeartRate;
// min heart rate
@property (nonatomic) NSUInteger minHeartRate;
// start time
@property (nonatomic) NSDate *startTime;
// user parameters
@property (nonatomic) NSUInteger userWeight;
// splits
@property (nonatomic) NSMutableArray *splits;
// current gps strength
@property (nonatomic) CLLocationAccuracy currentGpsStrength;

- (void) onSessionBegin:(id)session;
- (void) onSessionFinished:(id)session;
// call this when a location sample is added
- (void) onLocationAdded:(CLLocation *)newLocation workout:(id)workout session:(id)session;
// call this when a heart rate sample is added
- (void) onHeartRateAdded:(NSUInteger)heartRate workout:(id)workout session:(id)session;
- (XJSplit *) getOrCreateSplit:(NSUInteger)splitID;

- (void) buildSummary:(id) stdWorkout;

- (void) dump;

@end
