//
//  HeartRateDevice.h
//  BTLE Transfer
//
//  Created by 张志阳 on 15/5/13.
//  Copyright (c) 2015年 Apple. All rights reserved.
//
#import <CoreBluetooth/CoreBluetooth.h>

@protocol HeartRateDelegate

@required
-(void)didUpdateHeartRate:(unsigned short) heartRate;
-(void)isheartRateAvailable: (BOOL)available;
@end


@interface HeartRateDevice:NSObject
@property (nonatomic) BOOL simulator;
/**
 *Called after init to start scan/connect heart rate device,
 *delegate should be responsible for implementing HeartRateDelegate protocol
 *whenever heart rate is updated, tdidUpdateHeartRate will be exected
 **/
-(instancetype)init:(id)delegate;

@end

