//
//  XJHistoryCellView.m
//  Pao123
//
//  Created by 张志阳 on 15/6/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJDetailedHistoryCell.h"

@implementation XJDetailedHistoryCell

- (void)setImage:(UIImage *)img {
    if (![img isEqual:_image]) {
        _image = [img copy];
        self.historyCellImageView.image = _image;
    }
}

-(void)setName:(NSString *)n {
    if (![n isEqualToString:_name]) {
        _name = [n copy];
        self.historyCellLabelView1.text = _name;
    }
}

-(void)setValue:(NSString *)d {
    if (![d isEqualToString:_value]) {
        _value = [d copy];
        self.historyCellLabelView2.text = _value;
    }
}
@end
