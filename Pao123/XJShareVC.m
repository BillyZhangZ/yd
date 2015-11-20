//
//  XJShareVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/30/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJShareVC.h"
#import "model/XJWorkout.h"


@interface XJShareVC ()
{
    XJWorkout *_workout;
    UIImageView *_logo;
    UIButton *_btnDistance;
    UIButton *_btnDuration;
    UIButton *_btnCalorie;
    UIButton *_btnShare;
    UIButton *_btnClose;
}
@end

@implementation XJShareVC

- (instancetype)init:(id)workout
{
    self = [super init];
    if(self != nil)
    {
        _workout = workout;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    CGRect rcApp = [[UIScreen mainScreen] applicationFrame];
    int statusBarHeight = rcApp.origin.y;
    CGRect rc;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //----------------------------------------------------------------------------
    // configure status bar
    //----------------------------------------------------------------------------
    UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rcScreen.size.width, statusBarHeight)];
    statusBarView.backgroundColor = STATUSBARTINTCOLOR;
    [self.view addSubview:statusBarView];

    // logo
    rc = rcApp;
    rc.size.height = 64;
    rc.size.width = 64;
    rc.origin.x = rcApp.size.width/2 - rc.size.width/2;
    _logo = [[UIImageView alloc] initWithFrame:rc];
    _logo.image = [UIImage imageNamed:@"user.png"];
    [self.view addSubview:_logo];
    
    // 3 significant data
    rc.origin.x = 0;
    rc.origin.y = rc.origin.y + rc.size.height + 20;
    rc.size.width = rcApp.size.width;
    rc.size.height = TITLEBARHEIGHT;
    UILabel *lbl = [[UILabel alloc] initWithFrame:rc];
    lbl.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
//    [self.view addSubview:lbl];

    rc.size.width = (rcApp.size.width - 20) / 3;
    _btnDistance = [[UIButton alloc] initWithFrame:rc];
    [_btnDistance setTitle:[NSString stringWithFormat:@"%.2f\n距离(公里)", (float)_workout.summary.length/1000] forState:UIControlStateNormal];
    _btnDistance.titleLabel.numberOfLines = 2;
    _btnDistance.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_btnDistance setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    rc.origin.x += rc.size.width;
    _btnDuration = [[UIButton alloc] initWithFrame:rc];
    NSTimeInterval intval = _workout.summary.duration;
    int hour = (int)(intval/3600);
    int minute = (int)(intval - hour*3600)/60;
    int second = intval - hour*3600 - minute*60;
    [_btnDuration setTitle:[NSString stringWithFormat:@"%02d:%02d:%02d\n时长", hour, minute,second] forState:UIControlStateNormal];
    _btnDuration.titleLabel.numberOfLines = 2;
    _btnDuration.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_btnDuration setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    rc.origin.x += rc.size.width;
    _btnCalorie = [[UIButton alloc] initWithFrame:rc];
    NSUInteger calories = _workout.summary.calorie;
    [_btnCalorie setTitle:[NSString stringWithFormat:@"%d\n卡路里",(int)calories] forState:UIControlStateNormal];
    _btnCalorie.titleLabel.numberOfLines = 2;
    _btnCalorie.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_btnCalorie setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    [self.view addSubview:_btnDistance];
    [self.view addSubview:_btnDuration];
    [self.view addSubview:_btnCalorie];
    
    rc.origin.x = 10;
    rc.size.height = TITLEBARHEIGHT;
    rc.size.width = rcApp.size.width / 2 - 20;
    rc.origin.y = rcScreen.size.height - rc.size.height - 20;
    _btnShare = [[UIButton alloc] initWithFrame:rc];
    [_btnShare setTitle:@"微信分享" forState:UIControlStateNormal];
    _btnShare.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.3 alpha:1.0];
    [_btnClose addTarget:self action:@selector(onBtnShareClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnShare];
    
    rc.origin.x = rcApp.size.width / 2 + 10;
    _btnClose = [[UIButton alloc] initWithFrame:rc];
    [_btnClose setTitle:@"完成" forState:UIControlStateNormal];
    _btnClose.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.3 alpha:1.0];
    [_btnClose addTarget:self action:@selector(onBtnCloseClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnClose];
}

- (void) dealloc
{
    DEBUG_ENTER;
    NSLog(@"XJShareVC: dealloc");
    DEBUG_LEAVE;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) onBtnShareClicked:(id)sender
{
    
}

- (void) onBtnCloseClicked:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^(void){}];
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app onRunFinished:_workout];
    _workout = nil;
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
