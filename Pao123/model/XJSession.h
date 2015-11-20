//
//  KKSession.h
//  runhelper
//
//  Created by Zhenyong Chen on 5/18/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "XJWorkoutSummary.h"

@interface XJHeartRate : NSObject
@property (nonatomic) NSDate *timeStamp;
@property (nonatomic) NSUInteger rate;
@end


@interface XJSession : NSObject

// meters in this session
@property (nonatomic) CLLocationDistance length;
@property (nonatomic) NSDate *timeStart;
@property (nonatomic) NSDate *timeEnd; // if a session is open, then _timeEnd == nil
@property (nonatomic) NSUInteger number; // index of this session in the workout
@property (nonatomic) NSTimeInterval duration;
// locations in this session
@property (nonatomic) NSMutableArray *locations;
// heart rate values in this session
@property (nonatomic) NSMutableArray *heartRates;

- (instancetype) init:(NSUInteger)number;

// session is finished or not
- (BOOL) isOpen;
// start the session
- (void) start:(id)workout;
// finish this session
- (void) finish:(id)workout;

// add a new location data to this session
- (BOOL) appendLocation:(CLLocation *)loc ofworkout:(id)workout;
- (BOOL) appendHeartRate:(NSUInteger)heartRate at:(NSDate *)timeStamp ofworkout:(id)workout;

// storage support
- (NSString *) getSessionHeader:(id)workout;
- (NSString *) getSessionEnd:(id)workout;
- (NSString *) getSessionData:(id)workout range:(NSUInteger *)range;

- (BOOL) loadSession:(NSDictionary *)dict realTime:(BOOL)realtime workout:(id)wo;

// debug
- (void) dump;
@end
