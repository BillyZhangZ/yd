//
//  XJLocalWorkout.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/29/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "XJLocalWorkout.h"

@implementation XJLocalWorkout

- (instancetype) init:(unsigned int)userID
{
    self = [super init:userID];
    if(self != nil)
    {
        _uploadState = XJUPLOAD_NOTSTARTED;
    }

    return self;
}

@end
