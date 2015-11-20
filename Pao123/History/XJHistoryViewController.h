//
//  XJHistoryViewController.h
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "XJWorkoutManager.h"
#import "PullTableView.h"
@interface XJHistoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PullTableViewDelegate, XJWorkoutManagerDelegate>
{
}
@property (retain, nonatomic) IBOutlet  PullTableView*pullTableView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
- (void) presentWorkout:(id)workout;
@property (weak, nonatomic) IBOutlet UIButton *weekButton;
@property (weak, nonatomic) IBOutlet UIButton *monthButton;
@property (weak, nonatomic) IBOutlet UIButton *yearButton;
@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UIImageView *timeBar;

@end
