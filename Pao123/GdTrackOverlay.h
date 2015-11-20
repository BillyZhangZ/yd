//
//  GdTrackOverlay.h
//  Pao123
//
//  Created by Zhenyong Chen on 7/3/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import <UIKit/UIKit.h>

typedef struct tagSessionLocationPath
{
    NSInteger session; // -1: invalid
    NSInteger locationInSession; // -1: invalid
} SessionLocationPath;

@interface GdTrackOverlay : MAShape<MAOverlay>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) MAMapRect boundingMapRect;
@property (nonatomic, readonly) MACoordinateRegion boundingCoordRegion;
@property (nonatomic, readonly) NSArray *coordsArray;
@property CLLocation * lastLocation;

// play control: play till time; if not set, then always play to the end
@property (nonatomic) NSDate *playToTime;

// record last update location
@property SessionLocationPath lastSessionLocation;

// ending point image
@property (nonatomic) UIImage *endPoingImage;

+ (id)initWithCoordinates:(NSArray *)coordsArray;
- (void) updateGeometry;

@end
