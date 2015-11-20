//
//  XJWorkoutLocalRecorder.m
//  Pao123
//
//  Created by 张志阳 on 15/6/23.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJWorkoutLocalRecorder.h"
#import "XJWorkoutManager.h"
#import "AppDelegate.h"
#import "config.h"
#define SLEEP_TIME  1

/*
 *Local data file will keep open in thread lifetime for efficiency
 */
@interface XJWorkoutLocalRecorder ()
{
    __weak XJStdWorkout *_workoutAttached;
    NSThread            *_localRecordThread;
    
    NSFileManager       *_fileManager;
    NSFileHandle        *_localDataFileHandle;
    NSString            *_localDataFilePath;
}
@end

@implementation XJWorkoutLocalRecorder

- (instancetype) init:(__weak XJStdWorkout *)wo
{
    self = [super init];
    if(self != nil)
    {
        _workoutAttached = wo;
        _fileManager = nil;
        _localDataFileHandle = nil;
        _localDataFilePath = nil;
    }
    return self;
}

-(void)dealloc
{
    //主线程会调用stop方法
    //[self stop];
}

- (void) start
{
    DEBUG_ENTER;
    _fileManager = [NSFileManager defaultManager];
    
    if(_workoutAttached == nil)
        return;
    
    // prevent double calling
    NSLog(@"Local Saver thread starting ...");
    if(_localRecordThread != nil && _localRecordThread.executing)
        return;
    
    if(_localRecordThread == nil)
        _localRecordThread = [[NSThread alloc] initWithTarget:self selector:@selector(localSave:) object:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path = [paths objectAtIndex:0];
    
    NSString *workoutFileName = stringFromDate(_workoutAttached.summary.startTime);
    NSString *workoutDirPath=[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld/workouts/", (long)_workoutAttached.userID]];
    _localDataFilePath=[workoutDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", workoutFileName]];
    
    //判断文件夹是否存在并创建
    BOOL isDir = FALSE;
    BOOL isDirExist = [_fileManager fileExistsAtPath:workoutDirPath isDirectory:&isDir];
    BOOL ret = false;
    if(!(isDirExist && isDir))
    {
        ret = [_fileManager createDirectoryAtPath:workoutDirPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        if(!ret){
            NSLog(@"Create Account Directory Failed.");
            return;
        }
    }

    //if file not exists, create an empty one
    if (![_fileManager fileExistsAtPath:_localDataFilePath]) {
        [_fileManager createFileAtPath: _localDataFilePath contents:nil attributes:nil];
    }
    _localDataFileHandle = [NSFileHandle fileHandleForWritingAtPath:_localDataFilePath];
    
    [_localRecordThread start];
    DEBUG_LEAVE;
}

- (void) stop
{
    DEBUG_ENTER;
    if (_localRecordThread != nil) {
        [_localRecordThread cancel];
    }
    _localRecordThread = nil;
    
    if (_localDataFileHandle != nil) {
        [_localDataFileHandle closeFile];
    }
    _fileManager = nil;
    _localDataFileHandle = nil;
    _localDataFilePath = nil;
    DEBUG_LEAVE;
}

- (void) localSave:(void *)arg
{
    int curSession = 0;
    NSString *strToSave;
    
    DEBUG_ENTER;
    //
    // wait workout to begin
    //
    while (_workoutAttached.state == XJWS_CREATING || _workoutAttached.state == XJWS_PREPARING)
    {
        [NSThread sleepForTimeInterval:SLEEP_TIME];
        NSLog(@"Local Saver: wait begin");
        if([NSThread currentThread].cancelled)
        {
            NSLog(@"Local Saver: quit");
            return;
        }
    }
    
    NSLog(@"Local Saver: begin saving");
    
    //
    // Save workout header
    strToSave = [_workoutAttached getWorkoutHeader];
    if([self saveJson:strToSave] == NO)
        return;
    
    // Save sessions
    while (1)
    {
        NSArray *sessions = _workoutAttached.sessions;
        if(curSession < sessions.count)
        {
            XJSession *session = [sessions objectAtIndex:curSession];
            if([self localSaveSession:session] == NO)
                return;
            curSession++;
        }
        else
        {
            [NSThread sleepForTimeInterval:SLEEP_TIME];
        }
        
        // if finished, then no session will be appended
        if(_workoutAttached.state == XJWS_FINISHED && curSession == sessions.count)
        {
            break;
        }
        
        if([NSThread currentThread].cancelled)
        {
            NSLog(@"Local Saver: quit");
            return;
        }
    }
    
    NSLog(@"Local Saver: send workout end");
    
    //
    // Save workout end
    //
    strToSave = [_workoutAttached getWorkoutEnd];
     if([self saveJson:strToSave] == NO)
        return;
    
    NSDictionary *dict = [_workoutAttached workoutToDictionary];
    /*删除txt文件，转存到plist文件*/
    NSString *newPath = [[_localDataFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
    NSLog(@"%@", newPath);
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createFileAtPath: newPath contents:nil attributes:nil];
    [dict writeToFile:newPath atomically:YES];
    NSDictionary *data = [[NSDictionary alloc]initWithContentsOfFile:newPath];
    NSLog(@"%@",data);
    [fm removeItemAtPath:_localDataFilePath error:nil];

    NSLog(@"Local Saver: done and quit thread");
    DEBUG_LEAVE;

}

- (BOOL) localSaveSession:(XJSession *)session
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
    
    // Save location data
    while (1)
    {
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
        else
        {
            [NSThread sleepForTimeInterval:SLEEP_TIME];
        }
        
        if([NSThread currentThread].cancelled)
        {
            return NO;
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
    return [self saveJsonToLocalFile:string];
}

- (BOOL) saveJsonToLocalFile:(NSString *)string
{
    static unsigned long long fileSize = 0;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    fileSize = [_localDataFileHandle seekToEndOfFile];
    [_localDataFileHandle writeData:data];
    return YES;
}

@end
