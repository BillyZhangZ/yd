//
//  XJFriendGroupCell2.m
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJFriendGroupCell2.h"

@implementation XJFriendGroupCell2
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
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
