//
//  XJFriendGroupMemberListViewController.h
//  Pao123
//
//  Created by 张志阳 on 15/7/12.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJRunGroup.h"
@interface XJFriendGroupMemberListViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (unsafe_unretained, nonatomic) IBOutlet UINavigationBar *navigationBar;

-(instancetype)initWithGroup:(XJRunGroup *)group;

@end
