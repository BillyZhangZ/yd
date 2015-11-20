//
//  GdTrackOverlay.m
//  Pao123
//
//  Created by Zhenyong Chen on 7/3/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "GdTrackOverlay.h"

@interface GdTrackOverlay ()
{
    CLLocationDegrees _minLongitude;
    CLLocationDegrees _maxLongitude;
    CLLocationDegrees _minLatitude;
    CLLocationDegrees _maxLatitude;
}
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) MAMapRect boundingMapRect;
@property (nonatomic, readwrite) MACoordinateRegion boundingCoordRegion;
@property (nonatomic, readwrite) NSArray *coordsArray;
@end

@implementation GdTrackOverlay

@synthesize coordinate          = _coordinate;
@synthesize boundingMapRect     = _boundingMapRect;

- (instancetype) init
{
    self = [super init];
    if(self != nil) {
        _lastSessionLocation.session = -1;
        _lastSessionLocation.locationInSession = -1;
        _minLongitude = 0;
        _maxLongitude = 0;
        _minLatitude = 0;
        _maxLatitude = 0;
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"GdTrackOverlay: dealloc");
}

- (void) findBound:(NSArray *)coordsArray from:(SessionLocationPath)from to:(SessionLocationPath)to
{
    NSInteger firstSession = 0;
    if(from.session >= 0)
        firstSession = from.session;
    NSInteger endSession = coordsArray.count-1;
    if(to.session >= 0)
        endSession = to.session;

    for(NSInteger si = firstSession; si <= endSession; si++) {
        NSArray *coords = [coordsArray objectAtIndex:si];
        NSInteger pointCount = coords.count;

        NSInteger firstLocation;
        if(si == firstSession && from.locationInSession > 0)
            firstLocation = from.locationInSession;
        else
            firstLocation = 0;

        NSInteger endLocation;
        if(si == endSession && to.locationInSession > 0)
            endLocation = to.locationInSession;
        else
            endLocation = pointCount - 1;

        for (NSInteger i = firstLocation; i <= endLocation; i++) {
            CLLocation *location = [coords objectAtIndex:i];
            
            if(location.coordinate.longitude < _minLongitude || _minLongitude == 0)
                _minLongitude = location.coordinate.longitude;
            if(location.coordinate.longitude > _maxLongitude || _maxLongitude == 0)
                _maxLongitude = location.coordinate.longitude;
            if(location.coordinate.latitude < _minLatitude || _minLatitude == 0)
                _minLatitude = location.coordinate.latitude;
            if(location.coordinate.latitude > _maxLatitude || _maxLatitude == 0)
                _maxLatitude = location.coordinate.latitude;
        }
    }
}

- (void) updateGeometry
{
    SessionLocationPath newSessionLocation;
    newSessionLocation.session = -1;
    newSessionLocation.locationInSession = -1;

    for(NSInteger i=self.coordsArray.count-1; i>=0; i--) {
        NSArray *coords = [self.coordsArray objectAtIndex:i];
        if(coords == nil || coords.count == 0) {
            continue;
        }
        else {
            newSessionLocation.session = i;
            newSessionLocation.locationInSession = coords.count - 1;
            break;
        }
    }

    // empty?
    if(newSessionLocation.session == -1 || newSessionLocation.locationInSession == -1) {
        return;
    }

    [self findBound:self.coordsArray from:_lastSessionLocation to:newSessionLocation];
    
    _lastSessionLocation = newSessionLocation;

    CLLocationCoordinate2D loc;
    loc.longitude = (_minLongitude + _maxLongitude) / 2;
    loc.latitude = (_minLatitude + _maxLatitude) / 2;
    self.coordinate = loc;
    
    CLLocationCoordinate2D topLeft;
    topLeft.longitude = _minLongitude;
    topLeft.latitude = _minLatitude;
    CLLocationCoordinate2D botRight;
    botRight.longitude = _maxLongitude;
    botRight.latitude = _maxLatitude;

    // FIXME! is it correct for other countries?

    MAMapPoint mp1 = MAMapPointForCoordinate(topLeft);
    MAMapPoint mp2 = MAMapPointForCoordinate(botRight);

    self.boundingMapRect = MAMapRectMake(mp1.x, mp1.y, mp2.x - mp1.x, mp2.y - mp1.y);
    self.boundingCoordRegion = MACoordinateRegionMake(self.coordinate, MACoordinateSpanMake(_maxLatitude-_minLatitude, _maxLongitude-_minLongitude));
    
    // set initial last location (for real play, it will be fixed later)
    if(self.lastLocation == nil && _lastSessionLocation.session != -1)
    {
        NSArray *coords = [self.coordsArray objectAtIndex:_lastSessionLocation.session];
        NSAssert(_lastSessionLocation.locationInSession != -1, @"Bad location in session value");
        CLLocation *coord = [coords objectAtIndex:_lastSessionLocation.locationInSession];
        self.lastLocation = coord;
    }
}

- (CGPoint)pointForMapPoint:(MAMapPoint)mapPoint
{
    return CGPointMake(mapPoint.x, mapPoint.y);
}

+ (id)initWithCoordinates:(NSArray *)coordsArray
{
    GdTrackOverlay *overlay = [[self alloc] init];
    overlay.coordsArray = coordsArray;

    [overlay updateGeometry];

    return overlay;
}

@end
