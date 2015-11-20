//
//  XJWorkoutManager.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/5/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJStdWorkout.h"
#import "XJRemoteWorkout.h"
#import "XJLocalWorkout.h"
#define LAST_WORKOUT_COMPLETE 0
#define LAST_WORKOUT_NEED_TO_BE_CONTINUED 1
// callback after workout done or failed
@protocol XJWorkoutManagerDelegate
@required
-(void)historyWorkoutUpdated;
@end

@interface XJWorkoutManager : NSObject

@property (nonatomic) XJStdWorkout *currentWorkout;
@property (atomic) NSMutableArray *historyWorkouts;
@property  (nonatomic) NSInteger lastWorkoutCompleteFlag;
- (instancetype) init:(__weak id)account;

// create a new workout; the old one is appended to the history list
- (void) newCurrentWorkout;

// load history workouts, time before $before$
- (void) loadWorkoutListFromServer:(NSString *)beforeDate count:(NSUInteger)count delegate:(id)delegate;
// load history workouts from local storage
- (void) loadWorkoutsFromLocalDataFile;
- (void) storeWorkoutToDisk:(NSDictionary  *)workouts;
-(BOOL)deleteWorkout:(XJLocalWorkout *)workout;
// debug
- (void) dump;

@end
