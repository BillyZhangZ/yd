//
//  XJStdWorkout.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/18/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJStdWorkout.h"
#import "XJWorkoutRecorder.h"
#import "XJWorkoutLocalRecorder.h"

@interface XJStdWorkout ()
{
    XJWorkoutRecorder *_recorder;
    XJWorkoutLocalRecorder *_localRecorder;
    // use this timer to update duration
    NSTimer *_timer;
}

@property (atomic) CLLocation *lastLocation;

@end

@implementation XJStdWorkout

- (instancetype) init:(unsigned int)userID
{
    self = [super init:userID];
    if(self != nil)
    {
        _state = XJWS_CREATING;
        _uploadStatus = XJUPLOAD_NOTSTARTED;
        _realtime = YES;
        _recorder = [[XJWorkoutRecorder alloc] init];
        _localRecorder = [[XJWorkoutLocalRecorder alloc]init:self];
    }
    
    return self;
}

- (void) dealloc
{
    [_recorder stop];
    [_localRecorder stop];
}

- (void) setRealtime:(BOOL)realtime
{
    if(_realtime == realtime)
        return;
    if(_state != XJWS_CREATING)
        return;

    _realtime = realtime;

    if(_realtime)
        say(@"实时已打开");
    else
        say(@"实时已关闭");
}

- (void) switchToNewState:(XJWORKOUTSTATE)newState
{
    [_lock lock];
    
    if(newState == XJWS_CREATING)
    {
    }
    else if(newState == XJWS_PREPARING)
    {
        NSAssert(_state == XJWS_CREATING, @"State machine is wrong");
        // workout start time is now determined
        self.summary.startTime = [NSDate date];

        // start uploading to remote server
        if(self.realtime)
            [_recorder start:self];

        //start local data recorder, will atomatic stop when workout stopped
        [_localRecorder start];
    }
    else if(newState == XJWS_RUNNING)
    {
        NSAssert(_state == XJWS_PREPARING || _state == XJWS_PAUSED, @"State machine is wrong");
        XJSession *newSession = [[XJSession alloc] init:self.sessions.count];
        [self.sessions addObject:newSession];
        [newSession start:self];
        [self.summary onSessionBegin:newSession];

        // start timer
        if(_timer == nil)
            _timer =  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
        else
            [_timer setFireDate:[NSDate distantPast]];
        say(@"跑步已开始");
    }
    else if(newState == XJWS_PAUSED)
    {
        NSAssert(_state == XJWS_RUNNING, @"State machine is wrong");

        // pause timer
        [_timer setFireDate:[NSDate distantFuture]];
        
        // complete current session
        XJSession *currentSession = self.sessions.lastObject;
        NSAssert(currentSession != nil, @"No session found");
        [currentSession finish:self];
        say(@"跑步已暂停");
    }
    else if(newState == XJWS_FINISHED)
    {
        NSAssert(_state == XJWS_RUNNING || _state == XJWS_PAUSED, @"State machine is wrong");

        // complete current session
        XJSession *currentSession = self.sessions.lastObject;
        NSAssert(currentSession != nil, @"No session found");
        [currentSession finish:self];

        // delete timer
        [_timer invalidate];
        _timer = nil;

        // build summary
        [self.summary buildSummary:self];

        // upload to server: FIXME! right place here?
        if(self.realtime == NO)
            [_recorder start:self];

        say(@"跑步已停止");
    }

    [self setValue:[NSString stringWithFormat:@"%d", newState] forKey:@"state"];
    [_lock unlock];
}

- (BOOL) appendLocation:(CLLocation *)loc
{
    BOOL ret = NO;
    BOOL locationChanged = NO;

    // only record when running
    if(_state == XJWS_RUNNING)
    {
        // get last session and add it
        XJSession *lastSession = self.sessions.lastObject;
        NSAssert(lastSession != nil, @"null session");
        
        ret = [lastSession appendLocation:loc ofworkout:self];
        if (ret)
        {
            locationChanged = YES;
            // trigger KVO outside lock
            [self setValue:loc forKey:@"lastLocation"];
        }
    }

    return ret;
}

- (BOOL) appendHearRate:(NSUInteger)heartRate at:(NSDate *)timeStamp
{
    BOOL ret = NO;

    // only record when running
    if(self.state == XJWS_RUNNING)
    {
        // get last session and add it
        XJSession *lastSession = self.sessions.lastObject;
        NSAssert(lastSession != nil, @"null session");

        ret = [lastSession appendHeartRate:heartRate at:timeStamp ofworkout:self];
    }

    NSString *s = [[NSString alloc] initWithFormat:@"%d",(unsigned int)heartRate];
    [self setValue:s forKey:@"currentHeartRate"];

    return ret;
}

- (BOOL) validLocation:(CLLocation *)loc
{
    // if accuracy is too low, do not use this
    if(loc.horizontalAccuracy > 20)
        return NO;
    return YES;
}

-(void)onTimer:(id)sender
{
    NSUInteger count = self.sessions.count;
    NSUInteger i;
    NSTimeInterval total = 0;
    for(i=0; i<count; i++)
    {
        total += ((XJSession *)[self.sessions objectAtIndex:i]).duration;
    }

    NSString *s = [[NSString alloc] initWithFormat:@"%d",(unsigned int)total];
    [self setValue:s forKeyPath:@"summary.duration"];
}


@end
