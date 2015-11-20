//
//  GdMapReplayView.m
//  Pao123
//
//  Created by Zhenyong Chen on 7/2/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "GdMapReplayView.h"
#import "model/XJWorkout.h"
#import "GdTrackOverlayView.h"

@interface WorkoutOverlay : NSObject
@property (nonatomic) id workout;
@property (nonatomic) GdTrackOverlay *overlay;
@property (nonatomic) NSMutableArray *arrayOfPointList; // each XJSession has a list of points; a workout contains multiple XJSessions
@property (nonatomic) MAPointAnnotation *annotationStart;
@property (nonatomic) MAPointAnnotation *annotationEnd;
@end

@implementation WorkoutOverlay
@end

@interface GdMapReplayView ()
{
    NSMutableArray *_arrayOfOverlays; // WorkoutOverlay
}
@end

@implementation GdMapReplayView

- (instancetype) initWithFrame:(CGRect)Frame
{
    self = [super initWithFrame:Frame];

    if(self)
    {
        _enableUserLocation = NO;
        _arrayOfOverlays = [[NSMutableArray alloc] init];
        [self loadView];
    }

    return self;
}

- (void) dealloc
{
    NSLog(@"GdMapReplayView: dealloc");
    _gdMapView = nil;
    [_arrayOfOverlays removeAllObjects];
}

- (void) loadView
{
    _gdMapView = [[MAMapView alloc] initWithFrame:self.bounds];
    _gdMapView.delegate = self;

    _gdMapView.showsUserLocation = NO;    //YES 为打开定位，NO为关闭定位
    [_gdMapView setUserTrackingMode: MAUserTrackingModeNone animated:NO];
    _gdMapView.showsCompass= NO; // 设置成NO表示关闭指南针；YES表示显示指南针
    _gdMapView.showsScale= NO;  //设置成NO表示不显示比例尺；YES表示显示比例尺
    _gdMapView.scrollEnabled = YES;
    _gdMapView.zoomEnabled = YES;
    _gdMapView.mapType = MAMapTypeStandard;
    _gdMapView.buildingsDisabled = YES;
    _gdMapView.rotateEnabled = NO;
    _gdMapView.openGLESDisabled = NO;
    _gdMapView.rotateCameraEnabled = NO;
    _gdMapView.zoomLevel = 15;
    _gdMapView.centerCoordinate = CLLocationCoordinate2DMake(31.215931, 121.483928); // default value
    [self addSubview:_gdMapView];
}

- (void) setEnableUserLocation:(BOOL)enableUserLocation
{
    if(enableUserLocation == _enableUserLocation)
        return;
    
    if(enableUserLocation)
    {
        _gdMapView.showsUserLocation = YES;    //YES 为打开定位，NO为关闭定位
        [_gdMapView setUserTrackingMode: MAUserTrackingModeNone animated:NO];
        _gdMapView.desiredAccuracy = kCLLocationAccuracyBest;
        _gdMapView.pausesLocationUpdatesAutomatically = NO;
        _gdMapView.distanceFilter = 2;
        _gdMapView.customizeUserLocationAccuracyCircleRepresentation = YES;
    }
    else
    {
        _gdMapView.showsUserLocation = NO;    //YES 为打开定位，NO为关闭定位
        [_gdMapView setUserTrackingMode: MAUserTrackingModeNone animated:NO];
    }
    
    _enableUserLocation = enableUserLocation;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (WorkoutOverlay *) findWorkoutOverlay:(id)workout
{
    for(NSUInteger i=0; i<_arrayOfOverlays.count; i++) {
        WorkoutOverlay *wo = [_arrayOfOverlays objectAtIndex:i];
        if(wo.workout == workout)
            return wo;
    }
    
    return nil;
}

-(void) updatePaths:(NSDate *)playTo ofWorkout:(id)workout
{
    XJWorkout *wo = workout;
    if(wo == nil)
        return;

    int i;
    NSMutableArray *sessions = wo.sessions;
    NSUInteger sessionCount = sessions.count;

    WorkoutOverlay *workoutOverlay = [self findWorkoutOverlay:workout];
    if(workoutOverlay == nil) {
        workoutOverlay = [[WorkoutOverlay alloc] init];
        workoutOverlay.workout = workout;
        workoutOverlay.arrayOfPointList = [[NSMutableArray alloc] init];
        [_arrayOfOverlays addObject:workoutOverlay];
    }
    
    int j = (int)workoutOverlay.arrayOfPointList.count;

    for(i=0; i<sessionCount; i++)
    {
        XJSession *session = [sessions objectAtIndex:i];

        if(i <= j - 1)
        {
            // do nothing
        }
        else
        {
            [workoutOverlay.arrayOfPointList addObject:session.locations];
        }
    }
    
    if(workoutOverlay.overlay == nil && workoutOverlay.arrayOfPointList.count > 0)
    {
        workoutOverlay.overlay = [GdTrackOverlay initWithCoordinates:workoutOverlay.arrayOfPointList];
        [_gdMapView addOverlay:workoutOverlay.overlay];
    }

    // update new ending time
    if(workoutOverlay.overlay != nil)
    {
        workoutOverlay.overlay.playToTime = playTo;
    }

    // set annotations
    if(workoutOverlay.annotationStart == nil) {
        for(NSUInteger i=0; i<sessionCount; i++) {
            XJSession *session = [sessions objectAtIndex:i];
            if(session != nil) {
                CLLocation *firstLoc = session.locations.firstObject;
                if(firstLoc != nil)
                {
                    workoutOverlay.annotationStart = [self setAnnotationAt:firstLoc.coordinate withTitle:@"起点" withSubTitle:stringFromDate(firstLoc.timestamp)];
                    break;
                }
            }
        }
    }
    
    CLLocation *lastLoc = workoutOverlay.overlay.lastLocation;
    if(lastLoc != nil) {
        if(workoutOverlay.annotationEnd != nil) {
            [self.gdMapView removeAnnotation:workoutOverlay.annotationEnd];
        }
        workoutOverlay.annotationEnd = [self setAnnotationAt:lastLoc.coordinate withTitle:@"终点" withSubTitle:stringFromDate(lastLoc.timestamp)];
    }
}

- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id <MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[GdTrackOverlay class]])
    {
        GdTrackOverlayView *overlayView = [[GdTrackOverlayView alloc] initWithTrackOverlay:overlay];
        
        overlayView.lineWidth    = 6.f;
        overlayView.strokeColor  = [UIColor redColor];
        overlayView.lineDash     = NO;
        
        return overlayView;
    }
    else if (overlay == mapView.userLocationAccuracyCircle)
    {
        MACircleView *accuracyCircleView = [[MACircleView alloc] initWithCircle:overlay];

        accuracyCircleView.lineWidth    = 2.f;
        accuracyCircleView.strokeColor  = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        accuracyCircleView.fillColor    = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

        return accuracyCircleView;
    }

    return nil;
}

- (void)mapViewWillStartLocatingUser:(MAMapView *)mapView
{
    [self.cbDelegate mapViewWillStartLocatingUser:mapView];
}

-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    [self.cbDelegate mapView:mapView didUpdateUserLocation:userLocation updatingLocation:updatingLocation];
}

- (void) ensureVisibleAllLocations
{
    BOOL isFirst = YES;
    CLLocationDegrees _minLongitude, _maxLongitude, _minLatitude, _maxLatitude;
    _minLongitude = _maxLongitude = _minLatitude = _maxLatitude = 0;

    for(NSUInteger i=0; i<_arrayOfOverlays.count; i++) {
        WorkoutOverlay *wo = [_arrayOfOverlays objectAtIndex:i];
        if(wo.overlay == nil)
            continue;
        if(wo.overlay.boundingMapRect.size.width == 0 || wo.overlay.boundingMapRect.size.height == 0)
            continue;
        
        CLLocationDegrees n, s, w, e;
        s = wo.overlay.boundingCoordRegion.center.latitude - wo.overlay.boundingCoordRegion.span.latitudeDelta/2;
        n = wo.overlay.boundingCoordRegion.center.latitude + wo.overlay.boundingCoordRegion.span.latitudeDelta/2;
        w = wo.overlay.boundingCoordRegion.center.longitude - wo.overlay.boundingCoordRegion.span.longitudeDelta/2;
        e = wo.overlay.boundingCoordRegion.center.longitude + wo.overlay.boundingCoordRegion.span.longitudeDelta/2;

        NSAssert(s <= n && w <= e, @"Bad lat/lon");
        
        if(isFirst) {
            _minLongitude = w;
            _maxLongitude = e;
            _minLatitude = s;
            _maxLatitude = n;
        }
        else {
            if(w < _minLongitude)
                _minLongitude = w;
            if(e > _maxLongitude)
                _maxLongitude = e;
            if(s < _minLatitude)
                _minLatitude = s;
            if(n > _maxLongitude)
                _maxLatitude = n;
        }
        isFirst = NO;
    }

    // if not empty, change visible rect
    if(!isFirst) {
        MACoordinateRegion curRc = MACoordinateRegionForMapRect(_gdMapView.visibleMapRect);
        CLLocationDegrees n, s, w, e;
        w = curRc.center.longitude-curRc.span.longitudeDelta/2;
        e = curRc.center.longitude+curRc.span.longitudeDelta/2;
        s = curRc.center.latitude-curRc.span.latitudeDelta/2;
        n = curRc.center.latitude+curRc.span.latitudeDelta/2;

        if(_minLongitude < w || _maxLongitude > e || _minLatitude < s || _maxLatitude > n) {
            CLLocationCoordinate2D center;
            MACoordinateSpan span;
            center.longitude = (_minLongitude + _maxLongitude) / 2;
            center.latitude = (_minLatitude + _maxLatitude) / 2;
            span.longitudeDelta = (_maxLongitude - _minLongitude) * 1.1;
            span.latitudeDelta = (_maxLatitude - _minLatitude) * 1.1;
            MACoordinateRegion region = MACoordinateRegionMake(center, span);
            _gdMapView.centerCoordinate = center;
            [_gdMapView setRegion:region];
        }
    }
}

- (void) ensureVisibleLastLocation:(id)workout
{
    // get the location
    WorkoutOverlay *wo = [self findWorkoutOverlay:workout];
    if(wo == nil)
        return;
    CLLocation *last = wo.overlay.lastLocation;
    if(last == nil)
        return;

    MACoordinateRegion curRc = MACoordinateRegionForMapRect(_gdMapView.visibleMapRect);
    CLLocationDegrees n, s, w, e;
    CLLocationDegrees spanLon = curRc.span.longitudeDelta * 0.9;
    CLLocationDegrees spanLat = curRc.span.latitudeDelta * 0.9;
    w = curRc.center.longitude - spanLon/2;
    e = curRc.center.longitude + spanLon/2;
    s = curRc.center.latitude - spanLat/2;
    n = curRc.center.latitude + spanLat/2;

    CLLocationDegrees lat = last.coordinate.latitude;
    CLLocationDegrees lon = last.coordinate.longitude;
    if(lon < w || lon > e || lat < s || lat > n) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lon);
        [_gdMapView setCenterCoordinate:center animated:YES];
    }
}

- (MAPointAnnotation *) setAnnotationAt:(CLLocationCoordinate2D)loc withTitle:(NSString *)title withSubTitle:(NSString *)subTitle
{
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = loc;
    pointAnnotation.title = title;
    pointAnnotation.subtitle = subTitle;

    [self.gdMapView addAnnotation:pointAnnotation];

    return pointAnnotation;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation
                                                             reuseIdentifier:pointReuseIndetifier];
        }

        annotationView.canShowCallout               = YES;
        annotationView.animatesDrop                 = NO;
        annotationView.draggable                    = NO;
//        annotationView.rightCalloutAccessoryView    = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//        annotationView.pinColor                     = MAPinAnnotationColorGreen;
        MAPointAnnotation *ann = annotation;
        if([ann.title hasPrefix:@"起点"])
            annotationView.image = [UIImage imageNamed:@"history_start.png"];
        else if([ann.title hasPrefix:@"终点"])
            annotationView.image = [UIImage imageNamed:@"history_end.png"];
        else
            annotationView.pinColor = MAPinAnnotationColorRed;
        
        return annotationView;
    }
    if ([annotation isKindOfClass:[MAUserLocation class]])
    {
        static NSString *userLocationStyleReuseIndetifier = @"userLocationStyleReuseIndetifier";
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:userLocationStyleReuseIndetifier];
        }
        annotationView.image = [UIImage imageNamed:@"empty.png"];

        return annotationView;
    }

    return nil;
}


@end
