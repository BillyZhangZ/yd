//
//  XJFriendGroupInviteViewController.h
//  Pao123
//
//  Created by 张志阳 on 15/7/5.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJRunGroup.h"

@interface XJFriendGroupInviteViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

-(instancetype)initWithRunGroup:(XJRunGroup *)runGroup userId:(NSInteger)userId;
@end
