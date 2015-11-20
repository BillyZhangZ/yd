//
//  XJFriendManageViewController.h
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJRunGroup.h"

@interface XJFriendManageViewController : UIViewController
-(instancetype)initWithGroup:(XJRunGroup *)group;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
