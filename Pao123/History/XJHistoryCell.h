//
//  XJHistoryCellView.h
//  Pao123
//
//  Created by 张志阳 on 15/6/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJHistoryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *historyCellLabelView1;
@property (weak, nonatomic) IBOutlet UILabel *historyCellLabelView2;
@property (weak, nonatomic) IBOutlet UILabel *historyCellLabelView3;
@property (weak, nonatomic) IBOutlet UILabel *historyCellLabelView4;
@property (weak, nonatomic) IBOutlet UIImageView *imageIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *imageIndicatorBackground;
@property (copy, nonatomic) NSString *distance;
@property (copy, nonatomic) NSString *duration;
@property (copy, nonatomic) NSString *startTime;
@property (copy, nonatomic) NSString *reserved;
@end
