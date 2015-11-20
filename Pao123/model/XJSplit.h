//
//  XJSplit.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/19/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@interface XJSplitEndPosition : NSObject

@property (nonatomic) NSUInteger sessionIndex;
@property (nonatomic) NSUInteger locationIndex;
@property (nonatomic) double percent; // percent in [locationIndex, locationIndex+1]
@property (nonatomic) NSDate *timeStamp;

@end

@interface XJSplit : NSObject

// the last split is less than 1 KM
@property (nonatomic) NSInteger number;
@property (nonatomic) CLLocationDistance distance;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSUInteger altitudeMin;
@property (nonatomic) NSUInteger altitudeMax;
@property (nonatomic) double heartRateAvg;
@property (nonatomic) CLLocation *startLocation; // coordination of start point
@property (nonatomic) CLLocation *endLocation; // coordination of end point

// helper
@property (nonatomic) NSUInteger heartRateReceived; // how many heart rate messages received in this split by now
@property (nonatomic) CLLocation *lastLocation; // a temp variable only used by XJWorkoutSummary
@property (nonatomic) NSDate *beginTime; // a temp variable only used by XJWorkoutSummary

- (BOOL) loadSplit:(NSDictionary *)dict;

@end
