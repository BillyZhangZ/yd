//
//  XJRemoteWorkout.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/18/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "XJWorkout.h"

typedef enum tagWorkoutDownloadState
{
    XJDOWNLOAD_NA = 0, // if this workout is created locally, then no need to download
    XJDOWNLOAD_NOTSTARTED, // download has not been started
    XJDOWNLOAD_ONGOING, // is downloading
    XJDOWNLOAD_FAILED, // download failed
    XJDOWNLOAD_DONE // download successfully
} XJWORKOUTDOWNLOADSTATE;

@interface XJRemoteWorkout : XJWorkout

@property (nonatomic) XJWORKOUTDOWNLOADSTATE downloadState;
@property (nonatomic) NSUInteger dbID; // table ID in remote database

// set data from dictionary
// if realtime is YES, then do not end a session until a special flag is set
- (BOOL) loadWorkout:(NSDictionary *)dict realTime:(BOOL)realtime;
@end
