//
//  XJCoach.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/22/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJCoach.h"

@interface XJCoach ()
{
    __weak XJWorkout *_workoutAttached;
    NSThread *_thread;
}
@end

@implementation XJCoach

- (instancetype) init:(__weak XJStdWorkout *)wo
{
    self = [super init];
    if(self != nil)
    {
        _workoutAttached = wo;
    }
    
    return self;
}

- (void) start
{
    if(_workoutAttached == nil)
        return;

    if(_thread == nil)
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(coachThread:) object:nil];
    [_thread start];
}

- (void) pause
{
    say(@"跑步已暂停");
}

- (void) stop
{
    [_thread cancel];
    _thread = nil;
}

- (void) coachThread:(void *)arg
{
    say(@"跑步已开始");
    while(1)
    {
        if([NSThread currentThread].cancelled)
        {
            break;
        }
    }
    say(@"跑步已停止");
}

@end
