//
//  XJMainVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/12/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJMainVC.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "XJGoVC.h"

@interface XJMainVC () <CLLocationManagerDelegate,UIGestureRecognizerDelegate>
{
    UILabel *_lblHeartRate;
    UILabel *_lblGpsStrength;
//    UIImageView *_ivGps;
    // run control button
    UIButton *_btnRun;
    
    CLLocationManager *_locationManager;
}
@end

@implementation XJMainVC

- (void)viewDidLoad
{
    DEBUG_ENTER;
    [super viewDidLoad];
    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
    
    // Do any additional setup after loading the view.
    [self constructView];

    // get GPS strength
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    // set KVOs
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app.accountManager addObserver:self forKeyPath:@"currentAccount" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:"accountChanged"];
    [app.accountManager.currentAccount.workoutManager addObserver:self forKeyPath:@"currentWorkout" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:"currentWorkoutChanged"];
    [[app getCurrentWorkout] addObserver:self forKeyPath:@"currentHeartRate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:"WorkouttateToHeartRate"];
    DEBUG_LEAVE;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_locationManager startUpdatingLocation];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_locationManager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // update gps strength
    CLLocation *loc = [locations objectAtIndex:0];
    _lblGpsStrength.text = gpsLevel(loc.horizontalAccuracy);
}

- (void)dealloc
{
    DEBUG_ENTER;
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app.accountManager removeObserver:self forKeyPath:@"currentAccount" context:"accountChanged"];
    [app.accountManager.currentAccount.workoutManager removeObserver:self forKeyPath:@"currentWorkout" context:"currentWorkoutChanged"];
    [[app getCurrentWorkout] removeObserver:self forKeyPath:@"currentHeartRate" context:"WorkouttateToHeartRate"];
    DEBUG_LEAVE;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    DEBUG_ENTER;
    if(strcmp(context, "currentWorkoutChanged") == 0)
    {
        XJWorkout *oldWorkout = change[NSKeyValueChangeOldKey];
        XJWorkout *newWorkout = change[NSKeyValueChangeNewKey];
        [oldWorkout removeObserver:self forKeyPath:@"currentHeartRate" context:"WorkouttateToHeartRate"];
        [newWorkout addObserver:self forKeyPath:@"currentHeartRate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:"WorkouttateToHeartRate"];
    }
    else if(strcmp(context, "WorkouttateToHeartRate") == 0)
    {
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        XJStdWorkout *wo = [app getCurrentWorkout];
        NSString *heartRate = wo.currentHeartRate;
        if (heartRate.integerValue == 0)
            _lblHeartRate.text = @"--";
        else
            _lblHeartRate.text = heartRate;
    }
    else if(strcmp(context, "accountChanged") == 0)
    {
        XJAccount *oldAccount = change[NSKeyValueChangeOldKey];
        XJWorkout *oldWorkout = oldAccount ? oldAccount.workoutManager.currentWorkout : nil;
        XJAccount *newAccount = change[NSKeyValueChangeNewKey];
        XJWorkout *newWorkout = newAccount ? newAccount.workoutManager.currentWorkout : nil;
        if(oldAccount != nil)
            [oldAccount.workoutManager removeObserver:self forKeyPath:@"currentWorkout" context:"currentWorkoutChanged"];
        if(newAccount != nil)
            [newAccount.workoutManager addObserver:self forKeyPath:@"currentWorkout" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:"currentWorkoutChanged"];
        [oldWorkout removeObserver:self forKeyPath:@"currentHeartRate" context:"WorkouttateToHeartRate"];
        [newWorkout addObserver:self forKeyPath:@"currentHeartRate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:"WorkouttateToHeartRate"];
    }
    DEBUG_LEAVE;
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

- (void) constructView
{
    //-----------------------------------------------------------------------------
    // background
    //-----------------------------------------------------------------------------
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    CGRect rc = rcScreen;
    CGFloat par = BACKGROUNDPIC_WIDTH / BACKGROUNDPIC_HEIGHT;
    CGFloat expectedHeight = rc.size.width / par;
    rc.size.height = expectedHeight;
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:rc];
    bgView.image = [UIImage imageNamed:@"bg.png"];
    [self.view addSubview: bgView];

    //-----------------------------------------------------------------------------
    // Title bar
    //-----------------------------------------------------------------------------
    self.vcTitle = @"123GO!";
    self.leftButtonImage = @"menu.png";
//    self.rightButtonImage = @"liveshow.png";
    self.rightButtonTitle = @"直播: 开";
    [super constructView];
    [self.leftButton addTarget:self action:@selector(onBtnMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.rightButton addTarget:self action:@selector(onBtnBroadcast) forControlEvents:UIControlEventTouchUpInside];

    [self updateTitleBar];
    
    rc.size.width = FIRE_WIDTH;
    rc.size.height = FIRE_HEIGHT;
    rc.origin.x = (rcScreen.size.width - rc.size.width) / 2;
    rc.origin.y = FIRE_ABS_Y;
    UIImageView *fire = [[UIImageView alloc] initWithFrame:rc];
    fire.image = [UIImage imageNamed:@"fire.png"];
    [self.view addSubview:fire];
    
    #define MARGIN 32
    rc.size.height = MAJORDATA_TITLE_FONT_SIZE;
    rc.size.width = rcScreen.size.width - MARGIN*2;
    rc.origin.x = MARGIN;
    rc.origin.y = MAJORDATA_TITLE_ABS_Y;
    UILabel *timer = [[UILabel alloc] initWithFrame:rc];
    timer.text = @"00:00:00";
    timer.textColor = [UIColor whiteColor];
    timer.font = [UIFont fontWithName:MAJORDATA_TITLE_FONT_NAME size:MAJORDATA_TITLE_FONT_SIZE];
    timer.adjustsFontSizeToFitWidth = NO;
    [timer alignmentRectForFrame:CGRectMake(0, 0, 0, 0)];
    [timer setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:timer];

    //-----------------------------------------------------------------------------
    // Status panel
    //-----------------------------------------------------------------------------
    // label: heart rate value
    rc.size.width = lo_main_heartratevalue_width * rate_pixel_to_point;
    rc.size.height = lo_main_heartratevalue_height * rate_pixel_to_point;
    rc.origin.y = lo_main_heartratevalue_origin_y * rate_pixel_to_point;
    rc.origin.x = rcScreen.size.width / 2 - lo_main_heartratevalue_origin_x_offset_from_center * rate_pixel_to_point - rc.size.width;
    _lblHeartRate = [[UILabel alloc] initWithFrame:rc];
    _lblHeartRate.textColor = LO_MAIN_HEARTRATEVALUE_TEXT_COLOR;
    _lblHeartRate.font = [UIFont systemFontOfSize:lo_main_heartratevalue_font_size*rate_pixel_to_point];
    [self.view addSubview:_lblHeartRate];

    // label: heart rate name
    rc.size.width = lo_main_heartratename_width * rate_pixel_to_point;
    rc.size.height = lo_main_heartratename_height * rate_pixel_to_point;
    rc.origin.x = rc.origin.x - rc.size.width;
    rc.origin.y = _lblHeartRate.frame.origin.y - (rc.size.height - _lblHeartRate.frame.size.height)/2;
    UILabel *lable = [[UILabel alloc] initWithFrame:rc];
    lable.text = @"心率:";
    lable.textColor = LO_MAIN_HEARTRATENAME_TEXT_COLOR;
    lable.font = [UIFont systemFontOfSize:lo_main_heartratename_font_size * rate_pixel_to_point];
    [self.view addSubview:lable];

    // icon: heart rate
    rc.size.width = HEART_WIDTH;
    rc.size.height = HEART_HEIGHT;
    rc.origin.y = _lblHeartRate.frame.origin.y - (rc.size.height - _lblHeartRate.frame.size.height)/2;
    rc.origin.x = rc.origin.x - rc.size.width - 20 * rate_pixel_to_point;
    UIImageView *ivHeart = [[UIImageView alloc] initWithFrame:rc];
    ivHeart.image = [UIImage imageNamed:@"heart.png"];
    [self.view addSubview:ivHeart];
    
    // icon: gps
    rc.origin.x = rcScreen.size.width / 2 + lo_main_gps_origin_x_offset_from_center * rate_pixel_to_point;
    rc.size.width = GPS_WIDTH;
    rc.size.height = GPS_HEIGHT;
    rc.origin.y = _lblHeartRate.frame.origin.y - (rc.size.height - _lblHeartRate.frame.size.height)/2;
    UIImageView *ivGps = [[UIImageView alloc] initWithFrame:rc];
    ivGps.image = [UIImage imageNamed:@"GPS.png"];
    [self.view addSubview:ivGps];
    
    // label: gps name
    rc.origin.x += rc.size.width + 20 * rate_pixel_to_point;
    rc.size.width = lo_main_gpsname_width * rate_pixel_to_point;
    rc.size.height = lo_main_gpsname_height * rate_pixel_to_point;
    rc.origin.y = _lblHeartRate.frame.origin.y - (rc.size.height - _lblHeartRate.frame.size.height)/2;
    lable = [[UILabel alloc] initWithFrame:rc];
    lable.text = @"GPS:";
    lable.textColor = LO_MAIN_GPSNAME_TEXT_COLOR;
    lable.font = [UIFont systemFontOfSize:lo_main_gpsname_font_size * rate_pixel_to_point];
    [self.view addSubview:lable];

    // label: gps value
    rc.origin.x += rc.size.width;
    rc.size.width = lo_main_gpsvalue_width * rate_pixel_to_point;
    rc.size.height = lo_main_gpsvalue_height * rate_pixel_to_point;
    rc.origin.y = _lblHeartRate.frame.origin.y - (rc.size.height - _lblHeartRate.frame.size.height)/2;
    _lblGpsStrength = [[UILabel alloc] initWithFrame:rc];
    _lblGpsStrength.text = @"--";
    _lblGpsStrength.textColor = LO_MAIN_GPSVALUE_TEXT_COLOR;
    _lblGpsStrength.font = [UIFont systemFontOfSize:lo_main_gpsvalue_font_size * rate_pixel_to_point];
    [self.view addSubview:_lblGpsStrength];

    //-----------------------------------------------------------------------------
    // Run button
    //-----------------------------------------------------------------------------
    int remainY = rcScreen.size.height - (rc.origin.y + rc.size.height);
    if(remainY >= (lo_main_run_origin_y_from_bottom * rate_pixel_to_point) + 20) {
        rc.size.width = rc.size.height = lo_main_run_diameter * rate_pixel_to_point;
        rc.origin.x = (self.view.bounds.size.width - rc.size.width) / 2;
        rc.origin.y = (self.view.bounds.size.height - (lo_main_run_origin_y_from_bottom * rate_pixel_to_point));
    }
    else {
        float d = rcScreen.size.width > remainY ? remainY : rcScreen.size.width;
        d /= 2;
        rc.size.width = rc.size.height = d;
        rc.origin.x = (self.view.bounds.size.width - rc.size.width) / 2;
        rc.origin.y = (self.view.bounds.size.height - remainY/2 - rc.size.height/2);
    }
    _btnRun = [[UIButton alloc] initWithFrame:rc];
//    [_btnRun setBackgroundImage:[UIImage imageNamed:@"start.png"] forState:UIControlStateNormal];
    [_btnRun setTitle:@"开始跑" forState:UIControlStateNormal];
    [_btnRun setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnRun.titleLabel.font = [UIFont boldSystemFontOfSize:(lo_main_run_font_size * rate_pixel_to_point)];
    [_btnRun setBackgroundColor:DEFFGCOLOR];
    _btnRun.layer.cornerRadius = rc.size.width / 2;


    [_btnRun addTarget:self action:@selector(onRunClicked) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_btnRun];
}

- (void) onBtnMenu
{
    DEBUG_ENTER;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    [delegate showMenu];
    DEBUG_LEAVE;
}

- (void) onBtnBroadcast
{
    DEBUG_ENTER;
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJStdWorkout *wo = [app getCurrentWorkout];
    wo.realtime = !wo.realtime;

    [self updateTitleBar];
    DEBUG_LEAVE;
}

- (void) onRunClicked
{
    DEBUG_ENTER;
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJStdWorkout *wo = [app getCurrentWorkout];
    
    if(wo.state == XJWS_CREATING)
    {
        // switch workout state
        wo.state = XJWS_PREPARING;

        // pop up a detailed map
        XJGoVC *newVC = [[XJGoVC alloc] init];
        [self presentViewController:newVC animated:NO completion:^{}];
    }
    DEBUG_LEAVE;
}

- (void) updateTitleBar
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJStdWorkout *wo = [app getCurrentWorkout];
    if(wo.realtime)
    {
        [self.rightButton setTitle:@"直播: 开" forState:UIControlStateNormal];
//        self.rightButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.3 alpha:1.0];
        [self.rightButton setTitleColor:DEFFGCOLOR forState:UIControlStateNormal];
    }
    else
    {
        [self.rightButton setTitle:@"直播: 关" forState:UIControlStateNormal];
//        self.rightButton.backgroundColor = [UIColor darkGrayColor];
        [self.rightButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
}

- (void)handleGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    if(UIGestureRecognizerStateBegan == gesture.state ||
       UIGestureRecognizerStateChanged == gesture.state)
    {
        //根据被触摸手势的view计算得出坐标值
        CGPoint translation = [gesture translationInView:gesture.view];
        NSLog(@"%@", NSStringFromCGPoint(translation));
    }
    else
    {
        AppDelegate *app = [[UIApplication sharedApplication]delegate];
        [app showMenu];
    }
}
@end
