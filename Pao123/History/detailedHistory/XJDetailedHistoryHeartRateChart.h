//
//  XJDetailedHistoryHeartRateChart.h
//  Pao123
//
//  Created by 张志阳 on 15/6/18.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "GraphView.h"
#import "XJSession.h"
#define HEART_RATE_CHART_BASE_TAG -1101
#define HEART_RATE_CHART_SEGMENT_COUNT 6
#define HEART_RATE_CHART_PERCENTAGE_DEFAULT_HEIGHT 50
#define HEART_RATE_CHART_PERCENTAGE_HIGHLIGHT_HEIGHT 100
#define HEART_RATE_CHART_BASE_VALUE  120

@interface XJDetailedHistoryHeartRateChart : UIView<UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btn1;
@property (weak, nonatomic) IBOutlet UIButton *btn2;
@property (weak, nonatomic) IBOutlet UIButton *btn3;
@property (weak, nonatomic) IBOutlet UIButton *btn4;
@property (weak, nonatomic) IBOutlet UIButton *btn5;
@property (weak, nonatomic) IBOutlet UIButton *btn6;
@property (weak, nonatomic) IBOutlet UITabBar *bottomTabBar;
@property (weak, nonatomic) IBOutlet UILabel *averageHeartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *maximumHeartRateLabel;

- (void) loadWorkout:(XJWorkout *)workout;

@end
