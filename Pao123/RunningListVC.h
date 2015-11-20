//
//  RunningListVC.h
//  Pao123
//
//  Created by 张志阳 on 15/7/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullTableView.h"
@interface RunningListVC : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet PullTableView *tableView;

@end
