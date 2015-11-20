//
//  XJTraceTrackVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/15/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJTraceTrackVC.h"
#import <MAMapKit/MAMapKit.h>


@interface XJTraceTrackVC () <MAMapViewDelegate>
{
    MAMapView *_gdMapView;
    NSInteger _sessionToPaint;
    NSInteger _locationToPaint;
    CLLocationDegrees _minLongitude;
    CLLocationDegrees _maxLongitude;
    CLLocationDegrees _minLatitude;
    CLLocationDegrees _maxLatitude;
    
    NSDate *_startTime;
    NSTimer *_timer;
    CLLocation *_currentLocation;

    UIProgressView *_progressView;
    NSTimeInterval _currentTimePosition;
    UIButton *_btnFast;
    UIButton *_btnSlow;
    UIButton *_btnPlay;
    UILabel *_lblCurrentSpeed;
}
@end

@implementation XJTraceTrackVC

- (instancetype) init
{
    self = [super init];
    if(self != nil)
    {
        _speed = 1.0;
    }
    
    return self;
}


- (void)viewDidLoad {
    DEBUG_ENTER;
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _sessionToPaint = 0;
    _locationToPaint = 0;
    _minLongitude = _maxLongitude = _minLatitude = _maxLatitude = 0;

    self.vcTitle = @"观看路线图";
    self.leftButtonImage = @"back.png";
    [super constructView];
    [self.leftButton addTarget:self action:@selector(onBtnBack) forControlEvents:UIControlEventTouchUpInside];

    _gdMapView = [[MAMapView alloc] initWithFrame:self.clientRect];
    _gdMapView.delegate = self;

    _gdMapView.showsUserLocation = NO;    //YES 为打开定位，NO为关闭定位
    [_gdMapView setUserTrackingMode: MAUserTrackingModeNone animated:NO];
    _gdMapView.showsCompass= NO; // 设置成NO表示关闭指南针；YES表示显示指南针
    _gdMapView.showsScale= NO;  //设置成NO表示不显示比例尺；YES表示显示比例尺
    _gdMapView.scrollEnabled = YES;
    _gdMapView.zoomEnabled = YES;
    _gdMapView.zoomLevel = 13;
    _gdMapView.buildingsDisabled = YES;
    _gdMapView.rotateEnabled = NO;
    _gdMapView.openGLESDisabled = NO;
    _gdMapView.rotateCameraEnabled = NO;

    [self.view addSubview:_gdMapView];

    CGRect rc = self.clientRect;
    rc.size.height = 64;
    UILabel *lblBk = [[UILabel alloc] initWithFrame:rc];
    lblBk.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5];
    [self.view addSubview:lblBk];

    rc.origin.y += 8;
    rc.size.height = 16;
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressView.frame = rc;
    _progressView.tintColor = [UIColor redColor];
    _progressView.trackTintColor = [UIColor grayColor];
    [self.view addSubview:_progressView];
    _currentTimePosition = 0;

    rc.origin.x = 0;
    rc.origin.y += rc.size.height;
    rc.size.width = 64;
    rc.size.height = 32;
    _btnFast = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _btnFast.frame = rc;
    [_btnFast setTitle:@"加速" forState:UIControlStateNormal];
    [_btnFast addTarget:self action:@selector(onFastBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnFast];

    rc.origin.x += rc.size.width + 10;
    _btnSlow = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _btnSlow.frame = rc;
    [_btnSlow setTitle:@"减速" forState:UIControlStateNormal];
    [_btnSlow addTarget:self action:@selector(onSlowBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnSlow];

    rc.origin.x += rc.size.width + 10;
    _btnPlay = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _btnPlay.frame = rc;
    [_btnPlay setTitle:@"播放" forState:UIControlStateNormal];
    [_btnPlay addTarget:self action:@selector(onPlayBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnPlay];
    
    rc.origin.x += rc.size.width + 10;
    rc.size.width = 100;
    _lblCurrentSpeed = [[UILabel alloc] initWithFrame:rc];
    _lblCurrentSpeed.text = [NSString stringWithFormat:@"%.2f",_speed];
    [self.view addSubview:_lblCurrentSpeed];

    _startTime = [NSDate date];
    _timer =  [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];

    DEBUG_LEAVE;
}

- (void) onFastBtnClicked
{
    if(self.speed <= 128)
    {
        self.speed *= 2.0;
        _lblCurrentSpeed.text = [NSString stringWithFormat:@"%.2f",_speed];
    }
}

- (void) onSlowBtnClicked
{
    if(self.speed >= 1.0)
    {
        self.speed /= 2.0;
        _lblCurrentSpeed.text = [NSString stringWithFormat:@"%.2f",_speed];
    }
}

- (void) onPlayBtnClicked
{
    
}

- (void)didReceiveMemoryWarning {
    DEBUG_ENTER;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DEBUG_LEAVE;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)onTimer:(id)sender
{
    NSDate *now = [NSDate date];
    NSTimeInterval curTimeStamp = [now timeIntervalSinceDate:_startTime];
    curTimeStamp *= self.speed;

    XJSession *session = [self.workout.sessions firstObject];
    if(session == nil)
        return;

    NSDate *baseTime = session.timeStart;

    NSDate *playTo = [baseTime dateByAddingTimeInterval:curTimeStamp];

    [self updatePaths:playTo];
}

- (void) onBtnBack
{
    DEBUG_ENTER;
    [_timer invalidate];
    _timer = nil;
    [self dismissViewControllerAnimated:NO completion:^{}];
    DEBUG_LEAVE;
}

-(void) updatePaths:(NSDate *)playTo
{
    DEBUG_ENTER;

    NSUInteger i;
    NSMutableArray *sessions = self.workout.sessions;
    NSUInteger sessionCount = sessions.count;

    for(i=_sessionToPaint; i<sessionCount; i++)
    {
        XJSession *session = [sessions objectAtIndex:i];
        
        // determine the range
        NSUInteger j;
        for(j=_locationToPaint; j<session.locations.count; j++)
        {
            NSDate *locDate = ((CLLocation *)[session.locations objectAtIndex:j]).timestamp;
            if([playTo compare:locDate] == NSOrderedAscending)
                break;
        }

        NSRange range;
        range.location = _locationToPaint;
        range.length = j - _locationToPaint;
        if(range.length > 1)
        {
            NSArray *toPaint = [session.locations subarrayWithRange:range];
            [self drawLineWithLocationArray:toPaint];
            _locationToPaint += range.length - 1;
            _currentLocation = [session.locations objectAtIndex:_locationToPaint];
            [self ensureVisibleAllLocations];
        }
        
        if([session isOpen] == NO && _locationToPaint == session.locations.count-1)
        {
            _sessionToPaint++;
            _locationToPaint = 0;
        }
    }
    DEBUG_LEAVE;
}

- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id <MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth = 10.f;
        polylineView.strokeColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.6];
        
        return polylineView;
    }
    return nil;
}

- (void)drawLineWithLocationArray:(NSArray *)locationArray
{
    NSUInteger pointCount = [locationArray count];
    CLLocationCoordinate2D *coordinateArray = (CLLocationCoordinate2D *)malloc(pointCount * sizeof(CLLocationCoordinate2D));

    for (int i = 0; i < pointCount; i++) {
        CLLocation *location = [locationArray objectAtIndex:i];
        coordinateArray[i] = [location coordinate];

        if(location.coordinate.longitude < _minLongitude || _minLongitude == 0)
            _minLongitude = location.coordinate.longitude;
        if(location.coordinate.longitude > _maxLongitude || _maxLongitude == 0)
            _maxLongitude = location.coordinate.longitude;
        if(location.coordinate.latitude < _minLatitude || _minLatitude == 0)
            _minLatitude = location.coordinate.latitude;
        if(location.coordinate.latitude > _maxLatitude || _maxLatitude == 0)
            _maxLatitude = location.coordinate.latitude;
    }

    MAPolyline *maPolyline = [MAPolyline polylineWithCoordinates:coordinateArray count:pointCount];
    [_gdMapView addOverlay: maPolyline];

    CLLocation *l1 = [locationArray firstObject];
    CLLocation *l2 = [locationArray lastObject];
    _currentTimePosition += [l2.timestamp timeIntervalSinceDate:l1.timestamp];
    [self updateProgress];

    free(coordinateArray);
}

- (void) updateProgress
{
    NSTimeInterval total = self.workout.summary.duration;
    [_progressView setProgress:(_currentTimePosition/total) animated:NO];
}

- (void) ensureVisibleAllLocations
{
}


@end
