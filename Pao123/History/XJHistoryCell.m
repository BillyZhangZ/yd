//
//  XJHistoryCellView.m
//  Pao123
//
//  Created by 张志阳 on 15/6/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJHistoryCell.h"

@implementation XJHistoryCell
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);
    
    //上分割线，
   // CGContextSetStrokeColorWithColor(context, [UIColor colorWithHexString:@"ffffff"].CGColor);
    //CGContextStrokeRect(context, CGRectMake(5, -1, rect.size.width - 10, 1));
    
    //下分割线
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1.0]CGColor]);
    CGContextStrokeRect(context, CGRectMake(0, rect.size.height, rect.size.width, 2));
}

-(void)setDistance:(NSString *)distance {
    if (![distance isEqualToString:_distance]) {
        _distance = [distance copy];
        self.historyCellLabelView1.text = _distance;
    }
}

-(void)setDuration:(NSString *)duration {
    if (![duration isEqualToString:_duration]) {
        _duration = [duration copy];
        self.historyCellLabelView2.text = _duration;
    }
}

-(void)setStartTime:(NSString *)startTime {
    if (![startTime isEqualToString:_startTime]) {
        _startTime = [startTime copy];
        self.historyCellLabelView3.text = _startTime;
    }
}

-(void)setReserved:(NSString *)reserved
{
    if (![reserved isEqualToString:_reserved]) {
        _reserved = [reserved copy];
        self.historyCellLabelView4.text = _reserved;
    }
}
@end
