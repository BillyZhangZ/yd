//
//  XJDetailedHistoryHeartRateChart.m
//  Pao123
//
//  Created by 张志阳 on 15/6/18.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//
#import "config.h"
#import "XJDetailedHistoryHeartRateChart.h"
@interface XJDetailedHistoryHeartRateChart()
{
    unsigned long maximumIndex;
    unsigned long averageHeartRate, maximumHeartRate;
    GraphView *_graphView;
    __weak XJWorkout *_workout;
}
@end
@implementation XJDetailedHistoryHeartRateChart

-(void)awakeFromNib
{
    DEBUG_ENTER;
    [self.btn1 addTarget:self action:@selector(buttonsClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.btn2 addTarget:self action:@selector(buttonsClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.btn3 addTarget:self action:@selector(buttonsClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.btn4 addTarget:self action:@selector(buttonsClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.btn5 addTarget:self action:@selector(buttonsClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.btn6 addTarget:self action:@selector(buttonsClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    self.bottomTabBar.delegate = self;
    DEBUG_LEAVE;
}
/*
 *call once when enter detailed history
 */
-(void) updateHeartRateChart
{
    DEBUG_ENTER;
    int percentages[HEART_RATE_CHART_SEGMENT_COUNT] = {0};
    maximumIndex = 0;
    averageHeartRate = 0;
    maximumHeartRate = 0;
    int totalCount = 0;
    
    //statistic heart rate percentage
    for (int i= 0; i < [[_workout sessions] count]; i++) {
        XJSession *session = [[_workout sessions] objectAtIndex:i];
        for (int j = 0; j < [[session heartRates] count]; j++) {
            XJHeartRate *heartRate = [[session heartRates] objectAtIndex:j];
            unsigned long index;
            //generate level 0~5
            index = heartRate.rate > HEART_RATE_CHART_BASE_VALUE ?((NSInteger)heartRate.rate - HEART_RATE_CHART_BASE_VALUE + 10)/10: 0;
            if (index > 5) {
                index = 5;
            }
            percentages[index]++;
            // NSLog(@"%d", heartRate.rate);
            totalCount++;
            averageHeartRate += heartRate.rate;
            if (heartRate.rate > maximumHeartRate) {
                maximumHeartRate = heartRate.rate;
            }
        }
    }
    
    if(totalCount <= 0)
        return;

    averageHeartRate /= totalCount;
    
    self.averageHeartRateLabel.text = [NSString stringWithFormat:@"平均 %ld bpm", averageHeartRate];
    self.maximumHeartRateLabel.text = [NSString stringWithFormat:@"最大 %ld bpm", maximumHeartRate];
    
    NSLog(@"total heart rate count %d", totalCount);
    for (int i = 0; i < HEART_RATE_CHART_SEGMENT_COUNT; i++) {
        percentages[i] = percentages[i]*100/totalCount;
    }
    
    //drop err to percentages[0]
    percentages[0] = 0;
    for (int i = 1; i < HEART_RATE_CHART_SEGMENT_COUNT; i++) {
        percentages[0] += percentages[i];
    }
    percentages[0] = 100 - percentages[0];
    
    //refresh buttons sizes
    for (int i = 0; i < HEART_RATE_CHART_SEGMENT_COUNT; i++) {
        NSInteger percentage = percentages[i];
        NSInteger startX = 0;
        
        //find most percentage
        if (percentages[i] > percentages[maximumIndex]) {
            maximumIndex = i;
        }
        percentage = self.frame.size.width*percentage/100;
        if (i > 0)
        {
            startX = [self viewWithTag:HEART_RATE_CHART_BASE_TAG-i+1].frame.origin.x + [self viewWithTag:HEART_RATE_CHART_BASE_TAG-i+1].frame.size.width;
        }
        CGRect rc = CGRectMake(startX, self.frame.origin.y + HEART_RATE_CHART_PERCENTAGE_DEFAULT_HEIGHT, percentage, HEART_RATE_CHART_PERCENTAGE_DEFAULT_HEIGHT);
        [self viewWithTag:HEART_RATE_CHART_BASE_TAG-i].frame = rc;
        rc.origin.x = 0;
        rc.origin.y = 0;
        [self viewWithTag:HEART_RATE_CHART_BASE_TAG-i].bounds = rc;
        
        //tabar content
       // [[[self.bottomTabBar items] objectAtIndex:i] setTitle:[NSString stringWithFormat:@"%ld%%", (long)percentages[i]]];
        
        [((UIButton *)[self viewWithTag:HEART_RATE_CHART_BASE_TAG-i]) setTitle:[NSString stringWithFormat:@"%ld%%",(long)percentages[i]] forState:UIControlStateNormal];
      
        //[[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor redColor], NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];

    }
    
#pragma mark - fix me can't place bottomTabBar normally
    //current frame size is just what in interface builder
    CGRect rc = self.frame;
    rc.origin.x = rc.origin.y = 0;
    rc.size.height = 50;
    self.bottomTabBar.bounds = rc;
    rc.origin.x = 0;
    rc.origin.y = self.bounds.size.height - rc.size.height;
    //self.bottomTabBar.frame = rc;
    [self.bottomTabBar setFrame:rc];
    
    //default highlight the most percentage button
    [self highlightButton: HEART_RATE_CHART_BASE_TAG-maximumIndex];
    
    //display average heart rate and maximum heart rate
    rc = self.bounds;
    rc.origin.y = 150;
    rc.size.height = 50;
    rc.size.width /= 2;
    NSLog(@"%f %f %f %f",rc.origin.x, rc.origin.y, rc.size.width, rc.size.height);
    [self.averageHeartRateLabel setFrame:rc];
    rc.origin.x += rc.size.width + 1;
    [self.maximumHeartRateLabel setFrame:rc];
    
    // init _graphView and set up options
    _graphView = [[GraphView alloc]initWithFrame:CGRectMake(0, rc.origin.y + 60, self.frame.size.width, 180)];
    [_graphView setBackgroundColor:[UIColor darkGrayColor]];
    [_graphView setSpacing:10];
    [_graphView setFill:NO];
    [_graphView setStrokeColor:[UIColor redColor]];
    [_graphView setZeroLineStrokeColor:[UIColor greenColor]];
    [_graphView setFillColor:[UIColor orangeColor]];
    [_graphView setLineWidth:2];
    [_graphView setCurvedLines:NO];
    //to hold heart rates
    NSMutableArray *array = [[NSMutableArray alloc]init];
    NSArray *heartRateArray = [[[_workout sessions] objectAtIndex:0] heartRates];
    for (int i = 0; i < [heartRateArray count]; i++) {
        NSNumber *num = [[NSNumber alloc]initWithDouble:[[heartRateArray objectAtIndex:i] rate]];
        [array addObject: num];
    }
    [_graphView setArray:array];
    [_graphView setNumberOfPointsInGraph:(int)[array count]];
    [self addSubview:_graphView];
    
    DEBUG_LEAVE;
}

-(void)buttonsClicked:(id)sender
{
    DEBUG_ENTER;
    UIButton *btn = (UIButton *)sender;
    [self highlightButton:btn.tag];
    DEBUG_LEAVE;
}

-(void)highlightButton:(NSInteger)index
{
    DEBUG_ENTER;
    UIButton *btn = (UIButton *)[self viewWithTag:index];
    
    //恢复上一次点击的按钮高度
    for (int i = 0; i < HEART_RATE_CHART_SEGMENT_COUNT; i++) {
        if([self viewWithTag:HEART_RATE_CHART_BASE_TAG-i].bounds.size.height != HEART_RATE_CHART_PERCENTAGE_DEFAULT_HEIGHT)
        {
            CGRect rc = [self viewWithTag:HEART_RATE_CHART_BASE_TAG-i].bounds;
            rc.size.height = HEART_RATE_CHART_PERCENTAGE_DEFAULT_HEIGHT;
            [self viewWithTag:HEART_RATE_CHART_BASE_TAG-i].bounds = rc;
        }
    }
    //更新点击按钮高度，并产生动画
    CGRect rc = btn.bounds;
    rc.size.height = HEART_RATE_CHART_PERCENTAGE_HIGHLIGHT_HEIGHT;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    btn.bounds = rc;
    [UIView commitAnimations];
    DEBUG_LEAVE;
}
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    DEBUG_ENTER;
   // NSLog(@"%d item selected",item.tag);
    NSInteger index =  item.tag + 1201;
    index = HEART_RATE_CHART_BASE_TAG + index;
    [self highlightButton:index];
    DEBUG_LEAVE;
}


- (void) loadWorkout:(XJWorkout *)workout
{
    _workout = workout;
    [self updateHeartRateChart];
}

@end
