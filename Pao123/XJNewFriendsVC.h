//
//  XJNewFriendsVC.h
//  Pao123
//
//  Created by 张志阳 on 15/6/30.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJNewFriendsVC : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
-(instancetype)initWithApplyFriendList:(NSMutableArray *)applyFriendList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
