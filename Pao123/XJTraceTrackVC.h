//
//  XJTraceTrackVC.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/15/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "XJBaseNavVC.h"
#import "XJWorkout.h"

@interface XJTraceTrackVC : XJBaseNavVC

@property (nonatomic) XJWorkout *workout;
// playback speed
@property (nonatomic) double speed;

@end
