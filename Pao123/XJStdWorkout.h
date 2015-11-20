//
//  XJStdWorkout.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/18/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "XJWorkout.h"

// Standard workout: a running workout

typedef enum tagWorkoutState
{
    XJWS_CREATING = 0,
    XJWS_PREPARING,
    XJWS_RUNNING,
    XJWS_PAUSED,
    XJWS_FINISHED
} XJWORKOUTSTATE;

@interface XJStdWorkout : XJWorkout

// current status
@property (nonatomic, setter=switchToNewState:) XJWORKOUTSTATE state;
// uploading status
@property (nonatomic) XJWORKOUTUPLOADSTATE uploadStatus;
// a cache to the last location, its speed is invalid
@property (atomic, readonly) CLLocation *lastLocation;
// share to friends on the fly
@property (nonatomic) BOOL realtime;

// check location is valid
- (BOOL) validLocation:(CLLocation *)loc;
// append a location to current workout
- (BOOL) appendLocation:(CLLocation *)loc;
// append a heart rate value to current workout
- (BOOL) appendHearRate:(NSUInteger)heartRate at:(NSDate *)timeStamp;


@end
