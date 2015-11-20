//
//  XJHistoryCellView.h
//  Pao123
//
//  Created by 张志阳 on 15/6/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJDetailedHistoryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *historyCellImageView;
@property (weak, nonatomic) IBOutlet UILabel *historyCellLabelView1;
@property (weak, nonatomic) IBOutlet UILabel *historyCellLabelView2;

@property (copy, nonatomic) UIImage *image;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *value;
@end
