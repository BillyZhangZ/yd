//
//  XJCoach.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/22/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJStdWorkout.h"

@interface XJCoach : NSObject

- (instancetype) init:(XJStdWorkout *)wo;
- (void) start;
- (void) stop;

@end
