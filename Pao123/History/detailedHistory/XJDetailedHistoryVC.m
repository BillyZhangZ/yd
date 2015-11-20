//
//  XJDetailedHistoryVC.m
//  Pao123
//
//  Created by 张志阳 on 15/6/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "WXApiObject.h"
#import "XJDetailedHistoryVC.h"
#import "XJDetailedHistoryHeartRateChart.h"
#import "XJDetailedHistoryCell.h"
#import "XJDetailedHistoryMapView.h"
#import "XJDetailedHistorySegmentView.h"
#import "XJDetailedHistorySegmetCellTableViewCell.h"

#define PAGE_NUMBER 3

@interface XJDetailedHistoryVC ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>
{
    UIScrollView *_detailedHistoryScrollView;

    XJDetailedHistoryMapView * _detailedMapView;
    XJDetailedHistorySegmentView * _detailSegmentView;
    XJDetailedHistoryHeartRateChart *_heartRateView;
    
    UIButton *_btnMap;
    UIButton *_btnSplits;
    UIButton *_btnHeartRate;
}
@end

@implementation XJDetailedHistoryVC

#pragma mark - View lifetime

#define HIGHLIGHT_FG_COLOR [UIColor colorWithRed:0xff/255.0 green:0xff/255.0 blue:0xfe/255.0 alpha:0.5]
#define HIGHLIGHT_BK_COLOR [UIColor colorWithRed:0x2e/255.0 green:0x2e/255.0 blue:0x35/255.0 alpha:1.0]
#define NORMAL_FG_COLOR [UIColor colorWithRed:0xff/255.0 green:0xff/255.0 blue:0xfe/255.0 alpha:0.14]
#define NORMAL_BK_COLOR [UIColor clearColor]

- (void)viewDidLoad {
    DEBUG_ENTER;
    [super viewDidLoad];

    //-----------------------------------------------------------------------------
    // background
    //-----------------------------------------------------------------------------
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    CGRect rc = rcScreen;

    self.view.backgroundColor = [UIColor colorWithRed:0x24/255.0 green:0x25/255.0 blue:0x2a/255.0 alpha:1.0];
    //-----------------------------------------------------------------------------
    // Title bar
    //-----------------------------------------------------------------------------
    self.leftButtonImage = @"back.png";
    self.rightButtonImage = @"mainpage_share.png";
    [super constructView];
    [self.leftButton addTarget:self action:@selector(backButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.rightButton addTarget:self action:@selector(shareButtonClicked) forControlEvents:UIControlEventTouchUpInside];

    rc.size.width = 690 * rate_pixel_to_point;
    rc.size.height = 104 * rate_pixel_to_point;
    rc.origin.x = rcScreen.size.width/2 - rc.size.width/2;
    rc.origin.y = 198 * rate_pixel_to_point;
    UIView *v = [[UIView alloc] initWithFrame:rc];
    v.layer.cornerRadius = 4;
    v.backgroundColor = [UIColor colorWithRed:0x1f/255.0 green:0x20/255.0 blue:0x25/255.0 alpha:1.0];
    [self.view addSubview:v];
    
    rc.size.width = rc.size.width/3 - 4;
    rc.size.height = rc.size.height - 4;
    rc.origin.x = rc.origin.x + 2;
    rc.origin.y = rc.origin.y + 2;
    _btnMap = [[UIButton alloc] initWithFrame:rc];
    [_btnMap setTitle:@"路线总结" forState:UIControlStateNormal];
    [_btnMap setTitleColor:HIGHLIGHT_FG_COLOR forState:UIControlStateNormal];
    _btnMap.titleLabel.font = [UIFont systemFontOfSize:20*2*rate_pixel_to_point];
    _btnMap.backgroundColor = HIGHLIGHT_BK_COLOR;
    [_btnMap addTarget:self action:@selector(onBtnMapPageClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnMap];
    
    rc.origin.x += rc.size.width + 4 * 2;
    _btnSplits = [[UIButton alloc] initWithFrame:rc];
    [_btnSplits setTitle:@"分段" forState:UIControlStateNormal];
    [_btnSplits setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
    _btnSplits.titleLabel.font = [UIFont systemFontOfSize:20*2*rate_pixel_to_point];
    _btnSplits.backgroundColor = NORMAL_BK_COLOR;
    [_btnSplits addTarget:self action:@selector(onBtnSplitsPageClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnSplits];
 
    rc.origin.x += rc.size.width + 4 * 2;
    _btnHeartRate = [[UIButton alloc] initWithFrame:rc];
    [_btnHeartRate setTitle:@"心率" forState:UIControlStateNormal];
    [_btnHeartRate setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
    _btnHeartRate.titleLabel.font = [UIFont systemFontOfSize:20*2*rate_pixel_to_point];
    _btnHeartRate.backgroundColor = NORMAL_BK_COLOR;
    [_btnHeartRate addTarget:self action:@selector(onBtnHearRatePageClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnHeartRate];
    
    rc = rcScreen;
    rc.origin.y = v.frame.origin.y + v.frame.size.height + 40 * rate_pixel_to_point;
    rc.size.height -= rc.origin.y;
    _detailedHistoryScrollView = [[UIScrollView alloc]initWithFrame:rc];
    [self.view addSubview:_detailedHistoryScrollView];
   
    [self construct];

    DEBUG_LEAVE;
}

- (void) construct
{
    CGRect rc = _detailedHistoryScrollView.bounds;

    //scroll view height 0 to forbit scroll up-down
    _detailedHistoryScrollView.contentSize = CGSizeMake(self.view.bounds.size.width * PAGE_NUMBER, 0);
    _detailedHistoryScrollView.backgroundColor = [UIColor clearColor];
    _detailedHistoryScrollView.showsHorizontalScrollIndicator = NO;
    _detailedHistoryScrollView.showsVerticalScrollIndicator = NO;
    _detailedHistoryScrollView.pagingEnabled = YES;
    _detailedHistoryScrollView.delegate = self;

    //page 1
    _detailedMapView = [[XJDetailedHistoryMapView alloc]initWithFrame:rc];
    [_detailedHistoryScrollView addSubview:_detailedMapView];

    //page 2
    rc.origin.x += rc.size.width;
    _detailSegmentView = [[XJDetailedHistorySegmentView alloc]initWithFrame:rc];
    [_detailedHistoryScrollView addSubview:_detailSegmentView];

    //page 3
    rc.origin.x += rc.size.width;
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"XJDetailedHistoryHeartRateChart" owner:nil options:nil];
    _heartRateView = views[0];
    _heartRateView.frame = rc;
    [_detailedHistoryScrollView addSubview:_heartRateView];
}

- (void) setWorkout:(XJWorkout *)workout
{
    _workout = workout;
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc]init];
    [dateFormater setDateFormat:@"YY/MM/dd - HH:mm"];
    self.vcTitle = [dateFormater stringFromDate: _workout.summary.startTime];
}

- (void) viewWillAppear:(BOOL)animated
{
    [_detailedMapView loadWorkout:self.workout];
    [_detailSegmentView loadWorkout:self.workout];
    [_heartRateView loadWorkout:self.workout];
    [super viewWillAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    _detailedHistoryScrollView = nil;
    _detailedMapView = nil;
    _heartRateView = nil;
    [super viewDidDisappear:animated];
}

//before object is realeased, dealloc called
- (void)dealloc
{
    DEBUG_ENTER;
    NSLog(@"XJDetailedHistoryVC: dealloc");
    DEBUG_LEAVE;
}

- (void)didReceiveMemoryWarning {
    DEBUG_ENTER;
    [super didReceiveMemoryWarning];
    DEBUG_LEAVE;
}

#pragma mark - Buttons clicked

//back button
- (void) backButtonClicked
{
    DEBUG_ENTER;
    [self dismissViewControllerAnimated:NO completion:^{}];
    DEBUG_LEAVE;
}

//share button
- (void) shareButtonClicked
{
    DEBUG_ENTER;
    NSLog(@"Share button clicked");
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app sendTextContent:@"嗨喽，123Go!成长中。。。" withScene:WXSceneSession];
    DEBUG_LEAVE;
}

#pragma mark - scrollView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    _detailedHistoryPageControl.currentPage = scrollView.contentOffset.x/(scrollView.contentSize.width/PAGE_NUMBER);
    int cw = scrollView.contentSize.width/PAGE_NUMBER;
    float i = scrollView.contentOffset.x/cw;
    if(i < 0.5) {
        [_btnMap setTitleColor:HIGHLIGHT_FG_COLOR forState:UIControlStateNormal];
        _btnMap.backgroundColor = HIGHLIGHT_BK_COLOR;

        [_btnSplits setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
        _btnSplits.backgroundColor = NORMAL_BK_COLOR;

        [_btnHeartRate setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
        _btnHeartRate.backgroundColor = NORMAL_BK_COLOR;
    }
    else if(i < 1.5) {
        [_btnMap setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
        _btnMap.backgroundColor = NORMAL_BK_COLOR;

        [_btnSplits setTitleColor:HIGHLIGHT_FG_COLOR forState:UIControlStateNormal];
        _btnSplits.backgroundColor = HIGHLIGHT_BK_COLOR;
        
        [_btnHeartRate setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
        _btnHeartRate.backgroundColor = NORMAL_BK_COLOR;
    }
    else {
        [_btnMap setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
        _btnMap.backgroundColor = NORMAL_BK_COLOR;
        
        [_btnSplits setTitleColor:NORMAL_FG_COLOR forState:UIControlStateNormal];
        _btnSplits.backgroundColor = NORMAL_BK_COLOR;
        
        [_btnHeartRate setTitleColor:HIGHLIGHT_FG_COLOR forState:UIControlStateNormal];
        _btnHeartRate.backgroundColor = HIGHLIGHT_BK_COLOR;
    }
}

- (void) onBtnMapPageClicked
{
    _detailedHistoryScrollView.contentOffset = CGPointMake(0, 0);
}

- (void) onBtnSplitsPageClicked
{
    int cw = _detailedHistoryScrollView.contentSize.width/PAGE_NUMBER;
    _detailedHistoryScrollView.contentOffset = CGPointMake(cw*1, 0);
}

- (void) onBtnHearRatePageClicked
{
    int cw = _detailedHistoryScrollView.contentSize.width/PAGE_NUMBER;
    _detailedHistoryScrollView.contentOffset = CGPointMake(cw*2, 0);
}

@end
