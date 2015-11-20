//
//  RunningDetailListVC.h
//  Pao123
//
//  Created by 张志阳 on 15/7/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJRunGroup.h"
@interface RunningDetailListVC : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) XJRunGroup *runGroup;

-(instancetype)initWithRunGroup:(XJRunGroup *)group;
@end
