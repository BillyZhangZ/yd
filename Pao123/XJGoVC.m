//
//  XJGoVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/12/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJGoVC.h"
#import "MainPanelView.h"
#import "GdMapView.h"
#import "XJShareVC.h"
#import "XJCountDownView.h"

@interface XJGoVC () <UIScrollViewDelegate>
{
    // use scroll view as top container
    UIScrollView *_scrollView;
    
    // page 1: map panel (on the left)
    GdMapView *_mapPanel;
    // page 2: main panel
    MainPanelView *_mainPanel;
    
    // which workout this VC is serving
    XJStdWorkout *_workout;

    // test
    CAShapeLayer *_pathLayer;
    BOOL _animationCompleted;
}

@end

@implementation XJGoVC

- (void)viewDidLoad {
    DEBUG_ENTER;
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    _animationCompleted = NO;
    [self constructView];

    DEBUG_LEAVE;
}

- (void)didReceiveMemoryWarning {
    DEBUG_ENTER;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DEBUG_LEAVE;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // add observers
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    _workout = [app getCurrentWorkout];
    [_workout addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:"stateChanged"];
    [_workout addObserver:self forKeyPath:@"lastLocation" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:"locationChanged"];
    [_workout addObserver:self forKeyPath:@"currentHeartRate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:"heartRateChanged"];
    [_workout addObserver:self forKeyPath:@"summary.duration" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:"durationChanged"];
    [_workout addObserver:self forKeyPath:@"voiceHelper" options:NSKeyValueObservingOptionNew context:"voiceHelperChanged"];

    // update after KVO set
    [self update];

    // prevent idle
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // finally, pop up count down page
    CGRect rc = self.view.bounds;
    XJCountDownView *countDownView = [[XJCountDownView alloc]initWithFrame:rc];
    [self.view addSubview:countDownView];
}

- (void) viewWillDisappear:(BOOL)animated
{
    // restore idle
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    // remove observers
    [_workout removeObserver:self forKeyPath:@"state" context:"stateChanged"];
    [_workout removeObserver:self forKeyPath:@"lastLocation" context:"locationChanged"];
    [_workout removeObserver:self forKeyPath:@"currentHeartRate" context:"heartRateChanged"];
    [_workout removeObserver:self forKeyPath:@"summary.duration" context:"durationChanged"];
    [_workout removeObserver:self forKeyPath:@"voiceHelper" context:"voiceHelperChanged"];

    // do not show any more
    for (UIView *v in [self.view subviews]) {
        [v removeFromSuperview];
    }

    [_mapPanel stopMapping];
    _mainPanel = nil;
    _mapPanel = nil;
    _scrollView = nil;

    [super viewWillDisappear:animated];
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
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    CGRect rc;

    //----------------------------------------------------------------------------
    // Create container
    //----------------------------------------------------------------------------
    _scrollView = [[UIScrollView alloc] initWithFrame:rcScreen];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.contentSize = CGSizeMake(rcScreen.size.width*2, rcScreen.size.height);
    _scrollView.delegate = self;
//    _scrollView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:1.0 alpha:1.0];
    [self.view addSubview:_scrollView];

    //----------------------------------------------------------------------------
    // Create page 1: map panel
    //----------------------------------------------------------------------------
    _mapPanel = [[GdMapView alloc] initWithFrame:rcScreen];
    [_scrollView addSubview:_mapPanel];

    //----------------------------------------------------------------------------
    // Create page 2: main panel
    //----------------------------------------------------------------------------
    rc = rcScreen;
    rc.origin.x += rcScreen.size.width;
    _mainPanel = [[MainPanelView alloc] initWithFrame:rc];
    [_scrollView addSubview:_mainPanel];
    CGPoint pt = CGPointMake(rc.origin.x, 0);
    [_scrollView setContentOffset:pt];

    [_mainPanel.btnFinish addTarget:self action:@selector(onFinishClicked) forControlEvents:UIControlEventTouchUpInside];
//    [_mainPanel.btnPause addTarget:self action:@selector(onPauseClicked) forControlEvents:UIControlEventTouchUpInside];
    UILongPressGestureRecognizer * longPressGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressToDo:)];
    longPressGr.minimumPressDuration = 0;
    [_mainPanel.btnPause addGestureRecognizer:longPressGr];

    
    [_mainPanel.btnResume addTarget:self action:@selector(onResumeClicked) forControlEvents:UIControlEventTouchUpInside];
    [_mainPanel.btnSetVoice addTarget:self action:@selector(onSetVoiceClicked) forControlEvents:UIControlEventTouchUpInside];
}

//----------------------------------------------------------------------------
// Handle main panel events
//----------------------------------------------------------------------------

- (void) onFinishClicked
{
    DEBUG_ENTER;

    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    // save layout
    app.accountManager.currentAccount.btnLayout = _mainPanel.btnLayout;

    _workout.state = XJWS_FINISHED;
#if 0
    XJShareVC *shareVC = [[XJShareVC alloc] init:_workout];
    UIViewController *presentingVC = self.presentingViewController;
    NSAssert(presentingVC != nil, @"Bad presenting VC");
    [self dismissViewControllerAnimated:NO completion:^(void){}];
    [presentingVC presentViewController:shareVC animated:YES completion:^(){}];
#else
    void (^cb)(void) = ^(void) {
        [app onRunFinished:_workout];
    };
    [self dismissViewControllerAnimated:YES completion:cb];
#endif
    
    // create a new workout
    [app createNewWorkout];

    DEBUG_LEAVE;
}

- (void) onPauseClicked
{
    DEBUG_ENTER;
    DEBUG_LEAVE;
}

- (void) beginAnimation
{
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 2.0;
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    [pathAnimation setDelegate:self];

    CGRect rc = _mainPanel.btnPause.frame;
    double radius = rc.size.width / 2 /*+ lo_go_pause_outerline_width * rate_pixel_to_point*/;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius];

    _pathLayer = [CAShapeLayer layer];
    _pathLayer.position = CGPointMake(rc.origin.x + rc.size.width/2 - radius, rc.origin.y + rc.size.height/2 - radius);
    _pathLayer.path = path.CGPath;
    _pathLayer.strokeColor = [DEFFGCOLOR CGColor];
    _pathLayer.fillColor = nil;
    _pathLayer.lineWidth = lo_go_pause_outerline_width * rate_pixel_to_point;
    _pathLayer.lineJoin = kCALineJoinBevel;
    [_pathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];

    [_mainPanel.layer addSublayer:_pathLayer];
    _animationCompleted = NO;
}

- (void) endAnimation
{
    [_pathLayer removeAllAnimations];
    [_pathLayer removeFromSuperlayer];

    if(_animationCompleted == YES)
    {
        if(_workout.state == XJWS_RUNNING)
        {
            _workout.state = XJWS_PAUSED;
            [self update];
        }
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if(flag) {
        NSLog(@"Animation did stop");
        _animationCompleted = YES;
    }
    else {
        NSLog(@"Animation cancelled");
        _animationCompleted = NO;
    }
}

- (void)longPressToDo:(UILongPressGestureRecognizer *)gesture
{
    switch(gesture.state) {
    case UIGestureRecognizerStateBegan:
            // begin animation
            NSLog(@"Press begin");
            [self beginAnimation];
        break;
    case UIGestureRecognizerStateRecognized:
            // do not rely on this: always "recognized"
            NSLog(@"Press ok");
            [self endAnimation];
        break;
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
            NSLog(@"Press failed");
            // stop animation
            [self endAnimation];
        break;
    default:
            NSLog(@"Press ???");
        break;
    }
}

- (void) onResumeClicked
{
    DEBUG_ENTER;
    if(_workout.state == XJWS_PAUSED)
    {
        _workout.state = XJWS_RUNNING;
        [self update];
    }
    DEBUG_LEAVE;
}

- (void) onSetVoiceClicked
{
    DEBUG_ENTER;
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    app.accountManager.currentAccount.voiceHelper = !app.accountManager.currentAccount.voiceHelper;
    [self update];
    DEBUG_LEAVE;
}

- (void) update
{
    [_mainPanel update:_workout];
}

//---------------------------------------------------------------------------------------------
// Event handlers
//---------------------------------------------------------------------------------------------


// KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(strcmp(context, "stateChanged") == 0)
    {
        [_mainPanel update:_workout];
    }
    else if(strcmp(context, "locationChanged") == 0)
    {
        [_mapPanel update:_workout event:EF_UPDATE_LOCATION];
        [_mainPanel update:_workout eventFlag:EF_UPDATE_LOCATION];
    }
    else if(strcmp(context, "heartRateChanged") == 0)
    {
        [_mapPanel update:_workout event:EF_UPDATE_HEARTRATE];
        [_mainPanel update:_workout eventFlag:EF_UPDATE_HEARTRATE];
    }
    else if(strcmp(context, "durationChanged") == 0)
    {
        [_mapPanel update:_workout event:EF_UPDATE_DURATION];
        [_mainPanel update:_workout eventFlag:EF_UPDATE_DURATION];
    }
    else if(strcmp(context, "voiceHelperChanged") == 0)
    {
        [_mainPanel update:_workout];
    }
}

//---------------------------------------------------------------------------------------------
// Only support portrait
//---------------------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
