//
//  GdMapReplayView.h
//  Pao123
//
//  Created by Zhenyong Chen on 7/2/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>


@interface GdMapReplayView : UIView <MAMapViewDelegate>

@property (nonatomic) MAMapView *gdMapView;
// whether put the last location at center
@property (nonatomic) BOOL centerLastLocation;
@property (nonatomic) BOOL enableUserLocation;
@property (nonatomic) __weak id cbDelegate;

- (void) updatePaths:(NSDate *)playTo ofWorkout:(id)workout;
- (void) ensureVisibleAllLocations;
- (void) ensureVisibleLastLocation:(id)workout;

@end
