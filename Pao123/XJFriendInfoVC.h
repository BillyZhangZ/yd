//
//  XJFriendInfoVC.h
//  Pao123
//
//  Created by 张志阳 on 15/6/29.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJFriends.h"
@interface XJFriendInfoVC : UIViewController
@property (nonatomic) XJFriends *myself;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *nickName;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@end
