//
//  XJNewFriendsCell.h
//  Pao123
//
//  Created by 张志阳 on 15/6/30.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJNewFriendsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *portriatImage;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UIButton *approveButton;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;

@end
