//
//  XJLogger.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/21/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJLogger.h"

@interface XJLogger ()
{
    NSMutableArray *_logs;
    NSRecursiveLock *_lock;
    NSFileManager *_fileManager;
    NSFileHandle *_fileHandle;
    NSString *_filePath;
}
@end

@implementation XJLogger

- (instancetype) init
{
    self = [super init];
    if(self != nil)
    {
        _logs = [[NSMutableArray alloc] init];
        _lock = [[NSRecursiveLock alloc] init];

        NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* doc_path = [path objectAtIndex:0];
        _filePath = [doc_path stringByAppendingPathComponent:@"log.txt"];
        _fileManager = [NSFileManager defaultManager];
        //create log  file
        if (![_fileManager fileExistsAtPath:_filePath]) {
            [_fileManager createFileAtPath: _filePath contents:[@"123Go\n" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        }

        // send log of last run to server
        [self sendLogToServer];
    }
    
    
    return self;
}

- (void)dealloc
{
}

- (NSString *) loadLastCrashLog
{
    // TODO:
    return @"";}

- (void) sendLogToServer
{
    // load last log file
    NSString *lastLog = [self loadLogFile];
    if(lastLog != nil)
        [_logs addObject:lastLog];

    // load crash log
    NSString *lastCrashLog = [self loadLastCrashLog];
    if(lastCrashLog != nil)
        [_logs addObject:lastCrashLog];

    // send log to remote server
//    [_logs addObject:@"this is a test {} [] = ! \' \" ??? 呵哈 dkk"];
    NSString *urlString = URL_POST_DEBUGINFO;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [request setHTTPMethod:@"POST"];
    NSMutableString *string = [[NSMutableString alloc] init];
    NSUInteger i;
    for(i=0; i<_logs.count; i++)
    {
        [string appendString:[_logs objectAtIndex:i]];
    }
    NSString *time = stringFromDate([NSDate date]);
    NSDictionary *dic = @{@"info": string, @"time": time};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *tmp = [NSString stringWithFormat:@"debuginfo={\"users_id\":\"%d\",\"log\":[%@]}",(unsigned int)USERID, jsonString];
    NSLog(@"%@", tmp);
    [request setHTTPBody:[tmp dataUsingEncoding:NSUTF8StringEncoding]];
    [_logs removeAllObjects];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if(error != nil) {
	                                   [self restoreLogFile:string];
                               }
                           }];
}

- (void) log:(NSString *)string
{
    [_lock lock];
    NSString *tmp = [[NSString alloc] initWithFormat:@"[%@ %@] %@\n", stringFromDate([NSDate date]), [NSThread currentThread], string];
    [_logs addObject:tmp];
    // save immediately
    [self saveLocally: tmp];
    [_lock unlock];
}

- (void) saveLocally:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_filePath];
    [_fileHandle seekToEndOfFile];
    [_fileHandle writeData:data];
    [_fileHandle closeFile];
}

- (NSString *) loadLogFile
{
    _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_filePath];
    NSData *data = [_fileHandle readDataToEndOfFile];
    NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [_fileHandle truncateFileAtOffset:0];
    [_fileHandle closeFile];
    return string;
}

-(void) restoreLogFile:(NSString *)string
{
    NSData *currentData;
    NSData *dataToInsert = [string dataUsingEncoding:NSUTF8StringEncoding];
    [_lock lock];
    _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_filePath];
    currentData = [_fileHandle readDataToEndOfFile];
    [_fileHandle seekToFileOffset:0];
    
    [_fileHandle writeData:dataToInsert];
    [_fileHandle writeData:currentData];
    [_fileHandle closeFile];
    [_lock unlock];
}
@end
