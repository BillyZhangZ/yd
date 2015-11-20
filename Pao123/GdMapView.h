//
//  GdMapView.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/16/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GdMapReplayView.h"
#import "model/XJWorkout.h"


@interface GdMapView : UIView

@property (nonatomic) UIButton *btnLeft;
@property (nonatomic) UIButton *btnMiddle;
@property (nonatomic) UIButton *btnRight;
@property (nonatomic) GdMapReplayView *gdMapView;

- (void) update:(XJWorkout *)wo event: (NSUInteger)event;
// debug
- (void) stopMapping;

@end
