//
//  XJWorkoutManager.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/5/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJWorkoutManager.h"
#import "XJAccount.h"
#import "NSDictionaryNullReplacement.h"
@interface NetworkContext : NSObject
@property (nonatomic) id workoutManagerDelegate;
@property (nonatomic) NSMutableURLRequest *request;
@property (nonatomic) NSURLConnection *urlConnection;
@property (nonatomic) NSMutableData *receivedData;
@property (nonatomic) NSUInteger contentType; // 1: history list; 2: a single workout
@end

@implementation NetworkContext

- (instancetype) init
{
    self = [super init];
    if(self != nil)
    {
        _receivedData = [[NSMutableData alloc] init];
        _contentType = 0;
    }

    return self;
}

@end

@interface XJWorkoutManager ()
{
    NSRecursiveLock *_lock;
    NSMutableDictionary *_networkContexts;
    __weak XJAccount *_account;
}
@end

@implementation XJWorkoutManager
- (instancetype) init:(__weak id)account;
{
    self = [super init];
    if(self != nil)
    {
        _account = account;
        _lastWorkoutCompleteFlag = LAST_WORKOUT_COMPLETE;
        _lock = [[NSRecursiveLock alloc] init];
        _historyWorkouts = [[NSMutableArray alloc] init];
        [self newCurrentWorkout];
        _networkContexts = [NSMutableDictionary dictionary];
        // load history from local storage (TODO: put it in the background)
    }

    return self;
}

- (void) newCurrentWorkout
{
    [_lock lock];
    if(self.currentWorkout != nil)
    {
        // TODO: convert from XJStdWorkout to XJRemoteWorkout?
        [self.historyWorkouts insertObject:_currentWorkout atIndex:0];
    }

    XJStdWorkout *wo = [[XJStdWorkout alloc] init:(unsigned int)_account.userID];
    wo.summary.userWeight = _account.weight;
    [self setValue:wo forKey:@"currentWorkout"];

    [_lock unlock];
}

- (void) loadWorkoutsFromLocalDataFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *workoutFileList;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path = [paths objectAtIndex:0];
    NSString *workoutDirPath=[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld/workouts/", (long)_account.userID]];
    
    //fileList是workouts目录下所有文件名的数组
    workoutFileList = [fileManager contentsOfDirectoryAtPath:workoutDirPath error:&error];
    if (workoutFileList == nil) {
        NSLog(@"%ld本地无workout记录",(long)_account.userID);
        return;
    }
    NSLog(@"路径==%@,fileList%@",workoutDirPath,workoutFileList);
    
    //依次加载workout文件，文件分为两种：一种是完整的xml数据，另一种是非xml文件（运动实时存储的一系列item）
    for (NSString *workoutFileName in workoutFileList) {
        NSString *workoutFilePath = [workoutDirPath stringByAppendingPathComponent:workoutFileName];
        NSString *fileExtension = [workoutFilePath pathExtension];
        XJLocalWorkout *workout;
        if ([fileExtension isEqualToString:@"txt"]) {
            //文件为非xml文件
            workout = [self loadWorkoutFromTxt:workoutFilePath];
            if (workout != nil) {
                [_historyWorkouts insertObject:workout atIndex:0];
                NSDictionary *dict = [workout workoutToDictionary];
                /*删除txt文件，转存到plist文件*/
                NSString *newPath = [[workoutFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
                NSLog(@"%@", newPath);
                NSFileManager *fm = [NSFileManager defaultManager];
                [fm createFileAtPath: newPath contents:nil attributes:nil];
                [dict writeToFile:newPath atomically:YES];
                NSDictionary *data = [[NSDictionary alloc]initWithContentsOfFile:newPath];
                NSLog(@"%@",data);
                [fm removeItemAtPath:workoutFilePath error:nil];
            }
        }
        else if([fileExtension isEqualToString:@"plist"])
        {
            NSMutableDictionary *workoutDict = [[NSMutableDictionary alloc] initWithContentsOfFile:workoutFilePath];
            if (workoutDict == nil) {
                continue;
            }
            workout = [[XJLocalWorkout alloc] init:((unsigned int)_account.userID)];
            [workout loadWorkout:workoutDict realTime:NO];
            [_historyWorkouts insertObject:workout atIndex:0];
        }
        else
        {
            //unregnized file
        }
        NSLog(@"loading workout:%ld", (unsigned long)(workout.dbID));
        
    }
}

- (XJLocalWorkout *) loadWorkoutFromTxt:(NSString *)filePath
{
    // check account
    if(_account.userID == 0)
        return nil;

    //get and validate data file
    NSFileHandle *handle;
    NSFileManager * fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:filePath])
        return nil;

    handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (handle == NO)
        return nil;

    NSData* data = [[NSData alloc]initWithContentsOfFile:filePath];
    //seperate records
    NSAssert(data != nil, @"failed read file");
    NSString * str = [[NSMutableString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    NSArray * array = [str componentsSeparatedByString:@"workout="];

    XJLocalWorkout *wo = nil;

    //construct workout instance
    for (NSUInteger i=0; i<array.count; i++)
    {
        NSString *string = [array objectAtIndex:i];

        //first object is empty, caused by seperate
        if ([string isEqualToString: @""])
            continue;

        //get one record and parse
        NSData *dataRecord = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        if(dataRecord == nil) {
            NSLog(@"How return an empty workout record?");
            continue;
        }

        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:dataRecord options:NSJSONReadingMutableLeaves error:nil];

        if(dataRecord == nil || dict == nil)
        {
            NSLog(@"Bad string:\n%@", string);
            continue;
        }

        // is it a new workout?
        NSDate *workoutTime = getDateFromDictionary(dict, @"starttime");
        if(wo == nil || [workoutTime isEqualToDate:wo.summary.startTime] == NO)
        {
            // insert the old instance
            if(wo != nil)
                [_historyWorkouts insertObject:wo atIndex:0];

            // create a new instance
            wo = [[XJLocalWorkout alloc] init:(unsigned int)_account.userID];
        }

        if([wo loadWorkout:dict realTime:NO] == NO)
        {
            NSLog(@"Damaged workout");
            _lastWorkoutCompleteFlag = LAST_WORKOUT_NEED_TO_BE_CONTINUED;
        }
    }

    [handle closeFile];

    return wo;
}

#pragma fix me, 添加上传标志
//把从网络下载到workouts存储到本地
-(void)storeWorkoutToDisk:(NSDictionary  *)workouts
{
    NSDictionary *workoutDict = [workouts dictionaryByReplacingNullsWithZero];
    
    if (workoutDict == nil) {
        return;
    }
    NSString *workoutStartTime = [workoutDict valueForKey:@"starttime"];
    if ((NSNull *)workoutDict == [NSNull null]) {
        return;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path = [paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *workoutFileName = workoutStartTime;
    NSString *workoutDirPath=[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld/workouts/", (long)_account.userID]];
    NSString *workoutFilePath =[workoutDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", workoutFileName]];
    
    //判断文件夹是否存在并创建
    BOOL isDir = FALSE;
    BOOL isDirExist = [fm fileExistsAtPath:workoutDirPath isDirectory:&isDir];
    BOOL ret = false;
    if(!(isDirExist && isDir))
    {
        ret = [fm createDirectoryAtPath:workoutDirPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        if(!ret){
            NSLog(@"Create Account Directory Failed.");
            return;
        }
    }
    
    //如果文件存在则保持
    if (![fm fileExistsAtPath:workoutFilePath]) {
        [fm createFileAtPath: workoutFilePath contents:nil attributes:nil];
        [workoutDict writeToFile:workoutFilePath atomically:YES];
    }
}

- (void) addNetworkContext:(NSURLConnection *)connection forContext:(NetworkContext *)context
{
    NSString *key = [[NSString alloc] initWithFormat:@"%lld",(unsigned long long)connection];
    [_networkContexts setValue:context forKey:key];
}

- (NetworkContext *) getNetworkContext:(NSURLConnection *)connection
{
    NSString *key = [[NSString alloc] initWithFormat:@"%lld",(unsigned long long)connection];
    NetworkContext *context = [_networkContexts objectForKey:key];
    return context;
}

- (void) removeNetworkContext:(NSURLConnection *)connection forContext:(NetworkContext *)context
{
    NSString *key = [[NSString alloc] initWithFormat:@"%lld",(unsigned long long)connection];
    [_networkContexts removeObjectForKey:key];
}

// load workout list
- (void) loadWorkoutListFromServer:(NSString *)beforeDate count:(NSUInteger)count delegate:(id)delegate
{
    unsigned int userID = USERID;
    if(_account != nil)
        userID = (unsigned int)_account.userID;

    NSMutableString *urlPostWorkout = [[NSMutableString alloc] initWithString:URL_GET_WORKOUT_LIST];
    [urlPostWorkout appendFormat:@"%d", userID];

    NetworkContext *context = [[NetworkContext alloc] init];
    context.contentType = 1; // history list
    context.workoutManagerDelegate = delegate;

    NSURL *url = [NSURL URLWithString:urlPostWorkout];
    context.request = [NSMutableURLRequest requestWithURL:url  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    [context.request setHTTPMethod:@"POST"];

    NSString *string = [[NSString alloc] initWithFormat:@"limit=%d&date=%@&direction=backward",(unsigned int)count,beforeDate];
    [context.request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    context.urlConnection =[[NSURLConnection alloc]initWithRequest:context.request delegate:self];

    [self addNetworkContext:context.urlConnection forContext:context];
}

// load a single workout
- (void) loadWorkoutFromServer:(unsigned int)workoutID
{
    NetworkContext *context = [[NetworkContext alloc] init];
    context.contentType = 2; // load a single workout
    context.workoutManagerDelegate = nil;
    
    NSMutableString *urlPostWorkout = [[NSMutableString alloc] initWithString:URL_GET_WORKOUT];
    [urlPostWorkout appendFormat:@"%d",(unsigned int)workoutID];
    
    NSURL *url = [NSURL URLWithString:urlPostWorkout];
    context.request = [NSMutableURLRequest requestWithURL:url  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:100];
    [context.request setHTTPMethod:@"POST"];
    context.urlConnection = [[NSURLConnection alloc]initWithRequest:context.request delegate:self];

    [self addNetworkContext:context.urlConnection forContext:context];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NetworkContext *context = [self getNetworkContext:connection];
    if(context == nil)
        return;

    //clear receive block
    [context.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NetworkContext *context = [self getNetworkContext:connection];
    if(context == nil)
        return;

    [context.receivedData appendData:data];
}

- (void) didLoadWorkoutList:(NSURLConnection *)connection
{
    NetworkContext *context = [self getNetworkContext:connection];
    if(context == nil)
        return;

    if(context.receivedData == nil) {
        NSLog(@"Received data is nil");
        return;
    }

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:context.receivedData options:NSJSONReadingMutableLeaves error:nil];

    NSArray *workoutList = [dict objectForKey:@"workout"];

    if((NSNull *)workoutList != [NSNull null])
    {
        for(NSUInteger i=0; i<workoutList.count; i++)
        {
            NSDictionary *item = [workoutList objectAtIndex:i];

            // does this workout exist?
            NSDate *date = getDateFromDictionary(item, @"starttime");
            if(date == nil)
                continue;

            NSString *sDate = stringFromDate(date);
            XJWorkout *wo = [self getWorkout:sDate];
            if(wo != nil)
                continue;

            // download the workout
            NSString *sID = [item objectForKey:@"id"];
            if((NSNull *)sID == [NSNull null]) // bad
                continue;

            [self loadWorkoutFromServer:[sID intValue]];
        }
    }
    else
    {
        NSAssert(NO, @"Not valid workout list json string returned from server");
    }
}

- (void) didLoadSingleWorkout:(NSURLConnection *)connection
{
    NetworkContext *context = [self getNetworkContext:connection];
    if(context == nil)
        return;

    if(context.receivedData == nil) {
        NSLog(@"Received data is nil for this workout");
        return;
    }

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:context.receivedData options:NSJSONReadingMutableLeaves error:nil];

    XJRemoteWorkout *wo = [[XJRemoteWorkout alloc] init:((unsigned int)_account.userID)];
    if([wo loadWorkout:dict realTime:NO] == YES) {
        [_historyWorkouts addObject:wo];
        [self storeWorkoutToDisk:dict];
        NSLog(@"download workout +1");
    }
    else {
        NSAssert(NO, @"Not valid workout json string returned from server");
    }

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NetworkContext *context = [self getNetworkContext:connection];
    if(context == nil)
        return;

    if(context.contentType == 1)
    {
        [self didLoadWorkoutList:connection];
        // do not delete context for list for now
    }
    else if(context.contentType == 2)
    {
        [self didLoadSingleWorkout:connection];
        [self removeNetworkContext:connection forContext:context];
    }
    else
    {
        NSAssert(0, @"Bad connection received");
    }

    [self checkDownloadFinished];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (error.code == NSURLErrorTimedOut)
    {
        NSLog(@"请求超时");
    }

    NSLog(@"%@",[error localizedDescription]);
    
    NetworkContext *context = [self getNetworkContext:connection];
    if(context == nil)
        return;

    [self removeNetworkContext:connection forContext:context];
    [self checkDownloadFinished];
}

- (void) checkDownloadFinished
{
    if(_networkContexts.count > 1)
        return;

    NSEnumerator *enumerator = [_networkContexts keyEnumerator];
    id key = [enumerator nextObject];

    NetworkContext *context = [_networkContexts objectForKey:key];
    
    //将historyworkouts按日期排序
    NSSortDescriptor*sorter=[[NSSortDescriptor alloc]initWithKey:@"summary.startTime" ascending:NO];
    NSMutableArray *sortDescriptors=[[NSMutableArray alloc]initWithObjects:&sorter count:1];
    [_historyWorkouts sortUsingDescriptors:sortDescriptors];
    
    if(context.workoutManagerDelegate != nil)
    {
        [context.workoutManagerDelegate historyWorkoutUpdated];
        NSLog(@"History download: call back in thread %@", [NSThread currentThread]);
    }

    [_networkContexts removeAllObjects];
}

- (XJWorkout *) getWorkout:(NSString *)createTime
{
    XJWorkout *wo = nil;
    
    [_lock lock];
    
    if(stringFromDate(self.currentWorkout.summary.startTime) == createTime)
    {
        wo = self.currentWorkout;
    }
    else
    {
        int count = (int)self.historyWorkouts.count;
        int i;
        for(i=0; i<count; i++)
        {
            wo = [self.historyWorkouts objectAtIndex:i];
            NSDate *tm = wo.summary.startTime;
            NSString *sTime = stringFromDate(tm);
            if([sTime compare:createTime] == NSOrderedSame)
                break;
            wo = nil;
        }
    }

    [_lock unlock];
    
    return wo;
}

- (void) dump
{
    NSLog(@"Total history itmes: %d", (int)self.historyWorkouts.count);
    int i;
    for(i=0; i<self.historyWorkouts.count; i++)
    {
        XJWorkout *wo = [self.historyWorkouts objectAtIndex:i];
        NSAssert(wo != nil, @"Why insert an empty item into history list?");
        [wo dump];
    }
    
    NSLog(@"Dump current workout:");
    [self.currentWorkout dump];
}

#pragma mark fixme
-(BOOL)deleteWorkout:(XJLocalWorkout *)workout
{
    //删除网络
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_DELETE_WORKOUT];
    if ([workout respondsToSelector:@selector(dbID)] && workout.dbID != 0)
        [urlPost appendFormat:@"%lu",(unsigned long)workout.dbID];
    else
    {
        [urlPost appendFormat:@"%lu",(unsigned long)0];
    }
    
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            NSLog(@"无网路，无法删除");
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSInteger userId =[[dict valueForKey:@"id"] integerValue];
        if (userId != 0) {
            NSLog(@"删除网络纪录成功");
            //删除内存和本地
            [_historyWorkouts removeObject:workout];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString* path = [paths objectAtIndex:0];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *workoutFileName = stringFromDate(workout.summary.startTime);
            NSString *workoutDirPath=[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld/workouts/", (long)_account.userID]];
            NSString *workoutFilePath =[workoutDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", workoutFileName]];
            [fm removeItemAtPath:workoutFilePath error:nil];
        }
        else
        {
            NSLog(@"删除网络纪录成功");
            //删除内存和本地
            [_historyWorkouts removeObject:workout];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString* path = [paths objectAtIndex:0];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *workoutFileName = stringFromDate(workout.summary.startTime);
            NSString *workoutDirPath=[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld/workouts/", (long)_account.userID]];
            NSString *workoutFilePath =[workoutDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", workoutFileName]];
            [fm removeItemAtPath:workoutFilePath error:nil];
        }
        
    };
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if(error == nil && data != nil) {
                                   onDone(data);
                               }
                               else {
                                   onDone(nil);
                               }
                           }];

    return true;
}
@end
