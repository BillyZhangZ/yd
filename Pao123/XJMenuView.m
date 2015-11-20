//
//  XJMenuView.m
//  Pao123
//
//  Created by Zhenyong Chen on 5/27/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJMenuView.h"
#import "XJHistoryViewController.h"
#import "XJUserVC.h"

@interface XJMenuView ()
{
    // mask area
    UILabel *_maskArea;
}
@end


@implementation XJMenuView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        CGRect leftPart;
        CGRect rc;

        leftPart = frame;
        leftPart.size.width = lo_menu_width * rate_pixel_to_point;
        _maskArea = [[UILabel alloc] initWithFrame:leftPart];
        _maskArea.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
        [self addSubview:_maskArea];

        UIImageView *bk = [[UIImageView alloc] initWithFrame:leftPart];
        bk.image = [UIImage imageNamed:@"menubg.png"];
        [self addSubview:bk];
        // Header:
        rc = leftPart;
        rc.size.height = lo_menu_header_height * rate_pixel_to_point;

        CGRect rcPhoto = rc;
        const int radius = lo_menu_photo_diameter/2*rate_pixel_to_point;
        rcPhoto.origin.x = lo_menu_width * rate_pixel_to_point/2 - radius;
        rcPhoto.origin.y = lo_menu_photo_y_offset*rate_pixel_to_point;
        rcPhoto.size.width = radius*2;
        rcPhoto.size.height = radius*2;
        _ivPhoto = [[UIImageView alloc] initWithFrame:rcPhoto];
        _ivPhoto.image = [UIImage imageNamed:@"user.png"];
        _ivPhoto.layer.cornerRadius = radius;
        _ivPhoto.layer.masksToBounds=YES;

        // to respond to touch event ...
        UIControl *header = [[UIControl alloc] initWithFrame:rcPhoto];
        [self addSubview:header];
        [header addTarget:self action:@selector(onBtnUser:) forControlEvents:UIControlEventTouchUpInside];

        rcPhoto.origin.x = 0;
        rcPhoto.origin.y = lo_menu_nickname_y_offset * rate_pixel_to_point;
        rcPhoto.size.width = lo_menu_width * rate_pixel_to_point;
        rcPhoto.size.height = lo_menu_nickname_height * rate_pixel_to_point;
        _lblName = [[UILabel alloc] initWithFrame:rcPhoto];
        [_lblName setText:@"穿越时空的小碎步"];
        _lblName.textColor = MENU_NICKNAME_FONT_COLOR;
        _lblName.font = [UIFont systemFontOfSize:MENU_USER_NICKNAME_FONT_SIZE];
        _lblName.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_ivPhoto];
        [self addSubview:_lblName];

        // 6 menu items, 3 rows by 2 columns
        [self createMenuItem:0];
        [self createMenuItem:1];
        [self createMenuItem:2];
        [self createMenuItem:3];
        [self createMenuItem:4];
        [self createMenuItem:5];

        // if blank area is hit, then quit this menu
        [self addTarget:self action:@selector(onBtnClose:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

- (void) createMenuItem:(int)index
{
    CGRect rc;
    int originX;
    int originY;
    rc.size.width = rc.size.height = lo_menu_item_size * rate_pixel_to_point;
    rc.origin.y = lo_menu_header_height * rate_pixel_to_point + index/2 * rc.size.height;
    rc.origin.x = (lo_menu_width * rate_pixel_to_point - rc.size.width * 2 - 1) / 2;
    if(index % 2 == 1)
        rc.origin.x += rc.size.width + 1;
    originX = rc.origin.x;
    originY = rc.origin.y;
    UIButton *btn = [[UIButton alloc] initWithFrame:rc];
    btn.tag = index;
    [btn addTarget:self action:@selector(onBtnMenuItem:) forControlEvents:UIControlEventTouchUpInside];
    
    // divide rc
    rc.size.height *= 2.0 / 3;
    CGRect rcIcon;
    rcIcon.size.width = MENU_ITEM_ICON_SIZE;
    rcIcon.size.height = MENU_ITEM_ICON_SIZE;
    rcIcon.origin.x = (rc.size.width - rcIcon.size.width) / 2 + rc.origin.x;
    rcIcon.origin.y = (rc.size.height - rcIcon.size.height) / 2 + rc.origin.y;
    UIImageView *icon = [[UIImageView alloc] initWithFrame:rcIcon];
    
    rc.origin.y += rc.size.height;
    rc.size.height /= 2;
    UILabel *lbl = [[UILabel alloc] initWithFrame:rc];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.textColor = MENU_NICKNAME_FONT_COLOR;
    lbl.font = [UIFont systemFontOfSize:MENU_ITEM_TITLE_FONT_SIZE];

    switch(index) {
        case 0:
            icon.image = [UIImage imageNamed:@"icon1.png"];
            lbl.text = @"开始跑步";
            break;
        case 1:
            icon.image = [UIImage imageNamed:@"icon2.png"];
            lbl.text = @"跑步历史";
            break;
        case 2:
            icon.image = [UIImage imageNamed:@"icon3.png"];
            lbl.text = @"实时观看";
            break;
        case 3:
            icon.image = [UIImage imageNamed:@"icon4.png"];
            lbl.text = @"我的好友";
            break;
        case 4:
            icon.image = [UIImage imageNamed:@"icon5.png"];
            lbl.text = @"我的团";
            break;
        case 5:
        default:
            icon.image = [UIImage imageNamed:@"icon6.png"];
            lbl.text = @"设置";
            break;
    }

    CGRect tightRect = [lbl textRectForBounds:lbl.frame limitedToNumberOfLines:0];
    tightRect.origin.x = lbl.frame.origin.x;
    tightRect.size.width = lbl.frame.size.width;
    lbl.frame = tightRect;
    
    [self addSubview:btn];
    [self addSubview:icon];
    [self addSubview:lbl];
    
    if(index == 2 || index == 4) {
        rc.size.width = lo_menu_item_size * rate_pixel_to_point * 2 + 1;
        rc.size.height = 1;
        rc.origin.x = originX;
        rc.origin.y = originY - rc.size.height;
        UIView *v = [[UIView alloc] initWithFrame:rc];
        v.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8];
        [self addSubview:v];
    }
    else if(index == 1) {
        rc.size.width = 1;
        rc.size.height = lo_menu_item_size * rate_pixel_to_point * 3 + 2;
        rc.origin.x = originX - rc.size.width;
        rc.origin.y = originY;
        UIView *v = [[UIView alloc] initWithFrame:rc];
        v.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8];
        [self addSubview:v];
    }
}

- (void) onBtnUser:(id)sender
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app XJLog:@"Menu: onBtnUser"];
    [app onMenuItemClicked:@"User"];
}

- (void) onBtnClose:(id)sender
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app XJLog:@"Menu: onBtnClose"];
    [app onMenuItemClicked:@"cancelled"];
}

- (void) onBtnMenuItem:(id)sender
{
    NSString *itemName;

    UIButton *btn = sender;
    switch(btn.tag) {
        case 0: itemName = @"开始跑"; break;
        case 1: itemName = @"跑步历史"; break;
        case 2: itemName = @"实时观看"; break;
        case 3: itemName = @"好友们"; break;
        case 4: itemName = @"我的团"; break;
        case 5: itemName = @"设置"; break;
        default: return; break;
    }

    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app onMenuItemClicked:itemName];
}

@end
