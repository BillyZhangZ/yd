//
//  KKWorkout.h
//  runhelper
//
//  Created by Zhenyong Chen on 5/19/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "XJSession.h"
#import "XJWorkoutSummary.h"

typedef enum tagWorkoutUploadingState
{
    XJUPLOAD_NA = 0, // if this workout is downloaded from server, then no need to upload
    XJUPLOAD_NOTSTARTED, // upload has not been started
    XJUPLOAD_ONGOING, // uploading
    XJUPLOAD_FAILED, // upload failed
    XJUPLOAD_DONE // upload successfully
} XJWORKOUTUPLOADSTATE;

@interface XJWorkout : NSObject
{
    @public
    NSRecursiveLock *_lock;
}

// too bad: need user ID this workout belongs to
@property (readonly) unsigned int userID;
@property (nonatomic) XJWorkoutSummary *summary;
@property (nonatomic) NSMutableArray *sessions;

// report current heart rate; not relate to current state
@property (nonatomic) NSString *currentHeartRate;

- (instancetype) init:(unsigned int)userID;

- (NSUInteger) calcPace:(NSDate *)atTime;

// storage
- (NSString *) getWorkoutHeader;
- (NSString *) getWorkoutEnd;

// debug
- (void) dump;
- (NSString *) getWorkoutSplits;
- (NSDictionary *)workoutToDictionary;

@end
