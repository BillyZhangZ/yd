//
//  XJWorkoutRecorder.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/9/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJStdWorkout.h"

@interface XJWorkoutRecorder : NSObject

@property (nonatomic) NSUInteger bufferingDuration;

- (void) start:(__weak XJStdWorkout *)workoutToSave;
- (void) stop;

@end
