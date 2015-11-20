//
//  XJWorkoutRecorder.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/9/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJWorkoutRecorder.h"

@interface XJWorkoutRecorder ()
{
    __weak XJStdWorkout *_workoutAttached;
    NSThread *_realtimeThread;
}
@end

@implementation XJWorkoutRecorder

-(instancetype)init
{
    self = [super init];
    if (self) {
        _bufferingDuration = 5;
    }
    return self;
}

- (void) start:(__weak XJStdWorkout *)workoutToSave
{
    NSAssert(workoutToSave != nil, @"Nil workout to save!");
    NSAssert(_realtimeThread == nil && _workoutAttached == nil, @"Double calling me!");

    _workoutAttached = workoutToSave;

    _realtimeThread = [[NSThread alloc] initWithTarget:self selector:@selector(realtimeSave:) object:nil];
    [_realtimeThread start];
}

- (void) stop
{
    if(_realtimeThread != nil)
    {
        [_realtimeThread cancel];
        // wait until thread quit
        while([_realtimeThread isFinished] == NO)
        {
            [NSThread sleepForTimeInterval:1];
        }
        _realtimeThread = nil;
    }
    
    _workoutAttached = nil;
}

- (void) realtimeSave:(void *)arg
{
    int curSession = 0;
    NSString *strToSave;
    
    //
    // wait workout to begin
    //
    while (_workoutAttached.state == XJWS_CREATING || _workoutAttached.state == XJWS_PREPARING)
    {
        [NSThread sleepForTimeInterval:1];
        NSLog(@"Saver: wait begin");
        if([NSThread currentThread].cancelled)
        {
            NSLog(@"Saver: quit");
            goto quit;
        }
    }

    NSLog(@"Saver: begin saving");

    //
    // Send workout header
    //
    strToSave = [_workoutAttached getWorkoutHeader];
    if([self saveJson:strToSave] == NO)
        goto quit;

    // Send sessions
    while (1)
    {
        NSArray *sessions = _workoutAttached.sessions;
        if(curSession < sessions.count)
        {
            XJSession *session = [sessions objectAtIndex:curSession];
            NSAssert(session != nil, @"Saver: nil session");
            if([self realtimeSaveSession:session] == NO)
                goto quit;
            curSession++;
        }
        else
        {
            [NSThread sleepForTimeInterval:3];
        }
        
        // if finished, then no session will be appended
        if(_workoutAttached.state == XJWS_FINISHED && curSession >= sessions.count)
        {
            NSAssert(curSession == sessions.count, @"Impossible to exceed session count");
            break;
        }
        
        if([NSThread currentThread].cancelled)
        {
            NSLog(@"Saver: quit");
            goto quit;
        }
    }

    NSLog(@"Saver: send workout end");

    //
    // Send workout end
    //
    strToSave = [_workoutAttached getWorkoutEnd];
    if([self saveJson:strToSave] == NO)
        goto quit;

    NSLog(@"Saver: send ok");

quit:
    _workoutAttached = nil;
    NSLog(@"Saver: done and quit thread");
}

- (BOOL) realtimeSaveSession:(XJSession *)session
{
    NSString *strToSave;
    NSUInteger locIndex = 0; // begin index
    NSUInteger heartRateIndex = 0;

    //
    // Save session header
    //
    strToSave = [session getSessionHeader:_workoutAttached];
    if([self saveJson:strToSave] == NO)
        return NO;

    // Send location data
    while (1)
    {
        // buffer several seconds data and upload
        for(NSUInteger wait=0; wait<self.bufferingDuration; wait++) {
            [NSThread sleepForTimeInterval:1];
            
            if([NSThread currentThread].cancelled)
            {
                return NO;
            }
        }
        
        NSArray *locations = session.locations;
        NSArray *heartRates = session.heartRates;

        NSUInteger locCount = locations.count;
        NSUInteger rateCount = heartRates.count;

        if(locIndex < locCount || heartRateIndex < rateCount)
        {
            NSUInteger arr[] = {locIndex, locCount,heartRateIndex,rateCount};
            strToSave = [session getSessionData:_workoutAttached range:arr];
            if([self saveJson:strToSave] == NO)
                return NO;
            locIndex = locCount;
            heartRateIndex = rateCount;
        }

        // session finished?
        if([session isOpen] == NO)
        {
            if(locIndex == session.locations.count && heartRateIndex == session.heartRates.count)
                break;
        }
    }

    //
    // Send session end
    //
    strToSave = [session getSessionEnd:_workoutAttached];
    if([self saveJson:strToSave] == NO)
        return NO;

    return YES;
}

- (BOOL) saveJson:(NSString *)string
{
    NSAssert(string != nil, @"Saver: nil string");
//    NSLog(@"%@", string);
    return [self saveJsonToServer:string];
}

- (BOOL) saveJsonToServer:(NSString *)string
{
    NSString *urlPostWorkout = REMOTE_SERVER;
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error = [[NSError alloc] init];
    NSData *data;

    NSURL *url = [NSURL URLWithString:urlPostWorkout];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:6];
    [request setHTTPMethod:@"POST"];

    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];

    do {
        data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse  error:&error];

        if(data != nil)
        {
            NSLog(@"Sent it");
            break;
        }
        else
        {
            NSLog(@"Nil response, resend data");
        }

        if([NSThread currentThread].cancelled)
            return NO;

        // try 3 seconds later
        [NSThread sleepForTimeInterval:3];
    } while (1);

//    NSString *jsonResult = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
/*    NSString *strResult = [NSString stringWithFormat:@"return:%@\nid:%@",jsonResult, dict[@"id"]];
    NSLog(@"%@", strResult);
    */
    if(dict == nil)
    {
        myprintf("Bad json return\n");
    }

    return YES;
}

@end
