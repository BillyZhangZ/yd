//
//  XJDetailedHistorySegmetCellTableViewCell.h
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJDetailedHistorySegmetCellTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *distanceLable;
@property (weak, nonatomic) IBOutlet UILabel *paceLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeHighLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLowLabel;
@property (weak, nonatomic) IBOutlet UILabel *avgHeartRateLabel;
@end
