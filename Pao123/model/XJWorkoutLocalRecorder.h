//
//  XJWorkoutLocalRecorder.h
//  Pao123
//
//  Created by 张志阳 on 15/6/23.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJStdWorkout.h"
@interface XJWorkoutLocalRecorder : NSObject
- (instancetype) init:(__weak XJStdWorkout *)wo;

- (void) start;
- (void) stop;
@end
