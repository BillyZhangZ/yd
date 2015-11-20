//
//  GdMapView.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/16/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "GdMapView.h"
#import "AppDelegate.h"

@interface GdMapView ()
{
    UIButton *_btnPinMap;

    // simulator
    NSTimer *_gpsSimulator;
    NSDate *_gpsSimulatorStartTime;
}

@end

@implementation GdMapView

- (instancetype) initWithFrame:(CGRect)Frame
{
    self = [super initWithFrame:Frame];
    
    if(self)
    {
        [self loadView];
    }
    
    return self;
}

- (void) loadView
{
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    CGRect rcClient;
    if(self.frame.size.width == rcScreen.size.width && self.frame.size.height == rcScreen.size.height)
    {
        CGRect rcApp = [[UIScreen mainScreen] applicationFrame];
        int statusBarHeight = rcApp.origin.y;
        
        // configure status bar
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, statusBarHeight)];
        statusBarView.backgroundColor = DEFFGCOLOR;
        [self addSubview:statusBarView];
        
        rcClient = rcScreen;
        rcClient.origin.y += statusBarHeight;
        rcClient.size.height -= statusBarHeight;
    }
    else
    {
        rcClient = self.bounds;
    }
    
    UIView *separator;
    CGRect rc;
    CGRect rcSep = rc;
    XJWorkout *wo = [self getWorkout];

    // create the map
    rc = rcClient;
    _gdMapView = [[GdMapReplayView alloc] initWithFrame:rc];
    if([self isRobot]) {
        _gpsSimulator = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onGpsSimulate:) userInfo:nil repeats:YES];
        AppDelegate *app = [UIApplication sharedApplication].delegate;
        [app simulateHeartRate:YES];
    }
    else {
        _gdMapView.enableUserLocation = YES;
        AppDelegate *app = [UIApplication sharedApplication].delegate;
        [app simulateHeartRate:NO];
    }
    _gdMapView.cbDelegate = self;
    [self addSubview:_gdMapView];

    // left button
    rc = rcClient;
    rc.size.height = TITLEBARHEIGHT;
    rc.size.width = rcClient.size.width / 3;
    _btnLeft = [[UIButton alloc] initWithFrame:rc];
    _btnLeft.titleLabel.numberOfLines = 2;
    _btnLeft.titleLabel.textAlignment = NSTextAlignmentCenter;
    _btnLeft.backgroundColor = DEFFGCOLOR;
    [self addSubview:_btnLeft];
    [self showLeftButton:wo];

    /*
    // place a vertical bar
    rc.origin.x += rc.size.width;
    rc.size.width = 1;
    rcSep = rc;
    rcSep.size.height /= 2;
    rcSep.origin.y = rc.origin.y + (rc.size.height-rcSep.size.height)/2;
    separator = [[UIView alloc] initWithFrame:rcSep];
    separator.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:separator];
*/

    // draw middle button
    rc.origin.x += rc.size.width;
    rc.size.width = self.bounds.size.width / 3;
    _btnMiddle = [[UIButton alloc] initWithFrame:rc];
    _btnMiddle.titleLabel.numberOfLines = 2;
    _btnMiddle.titleLabel.textAlignment = NSTextAlignmentCenter;
    _btnMiddle.backgroundColor = DEFFGCOLOR;
    [self addSubview:_btnMiddle];
    [self showMiddleButton:wo];
/*
    // place a vertical bar
    rc.origin.x += rc.size.width;
    rc.size.width = 1;
    rcSep = rc;
    rcSep.size.height /= 2;
    rcSep.origin.y = rc.origin.y + (rc.size.height-rcSep.size.height)/2;
    separator = [[UIView alloc] initWithFrame:rcSep];
    separator.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:separator];
*/
    // draw right button
    rc.origin.x += rc.size.width;
    rc.size.width = self.bounds.size.width - rc.origin.x;
    _btnRight = [[UIButton alloc] initWithFrame:rc];
    _btnRight.titleLabel.numberOfLines = 2;
    _btnRight.titleLabel.textAlignment = NSTextAlignmentCenter;
    _btnRight.backgroundColor = DEFFGCOLOR;
    [self addSubview:_btnRight];
    [self showRightButton:wo];

    // create several buttons on the bottom to control map view
    rc = self.bounds;
    rc.origin.y = rc.size.height - TITLEBARHEIGHT;
    rc.size.height = TITLEBARHEIGHT;
    _btnPinMap = [[UIButton alloc] initWithFrame:rc];
    [_btnPinMap setBackgroundColor:DEFFGCOLOR];
    [_btnPinMap setTitle:@"解冻地图" forState:UIControlStateNormal];
    [_btnPinMap setTitle:@"冻结地图" forState:UIControlStateSelected];
    _btnPinMap.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_btnPinMap setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_btnPinMap setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [_btnPinMap addTarget:self action:@selector(onBtnPinMap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnPinMap];
    [self onBtnPinMap]; // freeze the map
}

- (void) stopMapping
{
    if(_gpsSimulator != nil) {
        [_gpsSimulator invalidate];
        _gpsSimulator = nil;
    }
    _gpsSimulatorStartTime = nil;
}

- (void) dealloc
{
    NSLog(@"GdMapView: dealloc");
}

- (BOOL) isRobot
{
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    if(app.accountManager.currentAccount.userID == 10000 || app.accountManager.currentAccount.userID == 120)
        return YES;
    else
        return NO;
}

-(void)onGpsSimulate:(NSTimer *)timer
{
    if(_gpsSimulatorStartTime == nil) {
        _gpsSimulatorStartTime = [NSDate date];
        [self mapViewWillStartLocatingUser:self.gdMapView.gdMapView];
    }
    else {
        // simulate a circle, with center(31.215931, 121.483928), radius (0.01, 0.01)
        const CLLocationDegrees centerLon = 121.483928;
        const CLLocationDegrees centerLat = 31.215931;
        const CLLocationDegrees radiusLon = 0.01 + (rand() % 8 / 800.0);
        CLLocationDegrees radiusLat = 0.01 + (rand() % 8 / 800.0);
        double angleSpeed = 0.01 + (rand() % 8 / 800.0);
        CLLocationDegrees alt = 15 + rand() % 30;
        double haccu = 5;
        double vaccu = 4;
        NSDate *curTime = [NSDate date];
        NSTimeInterval elapsed = [curTime timeIntervalSinceDate:_gpsSimulatorStartTime];
        CLLocationDegrees lon = centerLon + radiusLon * cos(elapsed * angleSpeed);
        CLLocationDegrees lat = centerLat + radiusLat * sin(elapsed * angleSpeed);
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat, lon);
        CLLocation *userLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:alt horizontalAccuracy:haccu verticalAccuracy:vaccu course:0 speed:-1 timestamp:curTime];

        BOOL updatingLocation = YES;
        [self mapView:self.gdMapView.gdMapView didUpdateUserLocationSim:userLocation updatingLocation:updatingLocation];
    }
}

- (void) onBtnPinMap
{
    DEBUG_ENTER;
    if(_gdMapView.gdMapView.scrollEnabled == YES)
    {
        _gdMapView.gdMapView.scrollEnabled = NO;
        _gdMapView.gdMapView.zoomEnabled = NO;
        [_btnPinMap setSelected:NO];
    }
    else
    {
        _gdMapView.gdMapView.scrollEnabled = YES;
        _gdMapView.gdMapView.zoomEnabled = YES;
        [_btnPinMap setSelected:YES];
    }
    DEBUG_LEAVE;
}

- (void) onBtnShowLocation
{
    DEBUG_ENTER;
    CLLocationCoordinate2D coord;
    MAUserLocation *loc = _gdMapView.gdMapView.userLocation;
    coord.latitude = loc.location.coordinate.latitude;
    coord.longitude = loc.location.coordinate.longitude;
    [_gdMapView.gdMapView setCenterCoordinate:coord animated:YES];
    DEBUG_LEAVE;
}

//---------------------------------------------------------------------------------------------
// Show content
//---------------------------------------------------------------------------------------------
- (void) showLeftButton:(XJWorkout *)wo
{
    if(wo == nil)
        return;

    NSMutableAttributedString *attribTitle;
    
    NSUInteger calories = wo.summary.calorie;
    NSString *sCalories = [NSString stringWithFormat:@"%d\n",(int)calories];
    attribTitle = [self formatText:sCalories subTitle:@"卡路里" isHead:NO];
    [_btnLeft setAttributedTitle:attribTitle forState:UIControlStateNormal];
}

- (void) showMiddleButton:(XJWorkout *)wo
{
    if(wo == nil)
        return;

    NSMutableAttributedString *attribTitle;

    NSUInteger pace = [wo calcPace:[NSDate date]];
    NSUInteger minutes = pace / 60;
    NSUInteger seconds = pace % 60;
    NSString *sPace = [NSString stringWithFormat:@"%02d:%02d\n",(unsigned int)minutes,(unsigned int)seconds];
    attribTitle = [self formatText:sPace subTitle:@"配速 (分/公里)" isHead:NO];
    [_btnMiddle setAttributedTitle:attribTitle forState:UIControlStateNormal];
}

- (void) showRightButton:(XJWorkout *)wo
{
    if(wo == nil)
        return;

    NSMutableAttributedString *attribTitle;
    
    NSTimeInterval intval = wo.summary.duration;
    int hour = (int)(intval/3600);
    int minute = (int)(intval - hour*3600)/60;
    int second = intval - hour*3600 - minute*60;
    NSString *dr = [NSString stringWithFormat:@"%02d:%02d:%02d\n", hour, minute, second];
    attribTitle = [self formatText:dr subTitle:@"时长" isHead:NO];
    [_btnRight setAttributedTitle:attribTitle forState:UIControlStateNormal];
}

- (void) update:(XJWorkout *)wo event:(NSUInteger)event
{
    if(event & EF_UPDATE_DURATION)
    {
        // pace
        [self showMiddleButton:wo];
        // duration
        [self showRightButton:wo];
    }

    if(event & EF_UPDATE_LOCATION)
    {
        [self.gdMapView updatePaths:[NSDate date] ofWorkout:wo];
        [self.gdMapView ensureVisibleLastLocation:wo];
        // calorie
        [self showLeftButton:wo];
    }
}

//---------------------------------------------------------------------------------------------
// Delegate functions of MAMapView
//---------------------------------------------------------------------------------------------
- (void)mapViewWillStartLocatingUser:(MAMapView *)mapView
{
    [self.gdMapView updatePaths:[NSDate date] ofWorkout:[self getWorkout]];
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocationSim:(CLLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    // update gps strength
    [self getWorkout].summary.currentGpsStrength = userLocation.horizontalAccuracy;

    XJStdWorkout *wo = [self getWorkout];
    if(wo == nil)
        return;
    
    if(wo.state == XJWS_RUNNING)
    {
        if(updatingLocation)
        {
            if([wo validLocation:userLocation] == YES) {
                [wo appendLocation:userLocation];
            }
        }
    }
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    // update gps strength
    [self getWorkout].summary.currentGpsStrength = userLocation.location.horizontalAccuracy;

    XJStdWorkout *wo = [self getWorkout];
    if(wo == nil)
        return;

    if(wo.state == XJWS_RUNNING)
    {
        if(updatingLocation)
        {
            if([wo validLocation:userLocation.location] == YES) {
                [wo appendLocation:userLocation.location];
            }
        }
    }
}

- (XJStdWorkout *) getWorkout
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJStdWorkout *wo = [app getCurrentWorkout];

    return wo;
}

- (NSMutableAttributedString *) formatText:(NSString *)title subTitle:(NSString *)sub isHead:(BOOL)head
{
    NSDictionary *attrDict1 = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:(head?96:20)],
                                 NSForegroundColorAttributeName: [UIColor whiteColor] };
    NSAttributedString *attrStr1 = [[NSAttributedString alloc] initWithString:title attributes: attrDict1];
    
    //第二段
    NSDictionary *attrDict2 = @{ NSFontAttributeName: [UIFont systemFontOfSize:10],
                                 NSForegroundColorAttributeName: [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0] };
    NSAttributedString *attrStr2 = [[NSAttributedString alloc] initWithString:sub attributes: attrDict2];
    
    //合并
    NSMutableAttributedString *attributedStr03 = [[NSMutableAttributedString alloc] initWithAttributedString: attrStr1];
    [attributedStr03 appendAttributedString: attrStr2];
    
    return attributedStr03;
}

@end
