//
//  XJDetailedHistoryMapView.m
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJDetailedHistoryMapView.h"
#import "config.h"
#import "GdMapReplayView.h"

@interface XJDetailedHistoryMapView() <UITableViewDelegate, UITableViewDataSource>
{
    GdMapReplayView *_gdMapView;
    UILabel *_lblDistance;
    UILabel *_lblDuration;
    UILabel *_lblCalorie;
    UITableView *_mapTableView;
    __weak XJWorkout *_workout;
}
@end

@implementation XJDetailedHistoryMapView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if(self)
    {
        CGRect rc = self.bounds;
        rc.size.height = 667 * rate_pixel_to_point;
        _gdMapView = [[GdMapReplayView alloc] initWithFrame:rc];
        _gdMapView.centerLastLocation = NO;
        [self addSubview:_gdMapView];
        UIView *v = [[UIView alloc] initWithFrame:rc];
        v.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        v.userInteractionEnabled = NO;
        [self addSubview:v];

        rc.origin.y = rc.origin.y + rc.size.height;
        rc.size.height = 7;
        UIView *fill = [[UIView alloc] initWithFrame:rc];
        fill.backgroundColor = [UIColor whiteColor];
        [self addSubview:fill];

        rc.origin.y = rc.origin.y + rc.size.height;
        rc.size.height = self.bounds.size.height - rc.origin.y;
        _mapTableView = [[UITableView alloc]initWithFrame:rc style:UITableViewStylePlain];
        _mapTableView.delegate = self;
        _mapTableView.dataSource = self;
        _mapTableView.rowHeight = 150 * rate_pixel_to_point;
        [self addSubview:_mapTableView];
        
        rc.size.height = 210 * rate_pixel_to_point;
        rc.size.width = _gdMapView.frame.size.width/3;
        rc.origin.x = _gdMapView.frame.origin.x;
        rc.origin.y = _gdMapView.frame.origin.y + _gdMapView.frame.size.height - rc.size.height;
        _lblDistance = [[UILabel alloc] initWithFrame:rc];
        _lblDistance.backgroundColor = [UIColor colorWithRed:0x1f/255.0 green:0x20/255.0 blue:0x25/255.0 alpha:0.8];
        _lblDistance.numberOfLines = 2;
        _lblDistance.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblDistance];
        rc.origin.x += rc.size.width;
        _lblDuration = [[UILabel alloc] initWithFrame:rc];
        _lblDuration.backgroundColor = [UIColor colorWithRed:0x1f/255.0 green:0x20/255.0 blue:0x25/255.0 alpha:0.8];
        _lblDuration.numberOfLines = 2;
        _lblDuration.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblDuration];
        rc.origin.x += rc.size.width;
        rc.size.width = _gdMapView.frame.origin.x + _gdMapView.frame.size.width - rc.origin.x;
        _lblCalorie = [[UILabel alloc] initWithFrame:rc];
        _lblCalorie.backgroundColor = [UIColor colorWithRed:0x1f/255.0 green:0x20/255.0 blue:0x25/255.0 alpha:0.8];
        _lblCalorie.numberOfLines = 2;
        _lblCalorie.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblCalorie];
    }

    return self;
}

- (void) loadWorkout:(XJWorkout *)workout
{
    _workout = workout;
    [_gdMapView updatePaths:[NSDate date] ofWorkout:workout];
    [_gdMapView ensureVisibleLastLocation:workout];
    [_mapTableView reloadData];

    NSAttributedString *richText;
    NSString *string;
    string = [NSString stringWithFormat:@"%.2f\n", (workout!=nil?workout.summary.length/1000:0)];
    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.1*2*rate_pixel_to_point];
    if(titleFont == nil)
        titleFont = [UIFont systemFontOfSize:28.1*2*rate_pixel_to_point];
    UIFont *subFont = [UIFont systemFontOfSize:18*2*rate_pixel_to_point];
    UIColor *titleClr = [UIColor whiteColor];
    UIColor *subClr = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.75];
    richText = [self formatRichText:string font1:titleFont color1:titleClr title2:@"距离 (公里)" font2:subFont color2:subClr];
    [_lblDistance setAttributedText:richText];
    int h, m, s;
    if(workout != nil) {
        s = workout.summary.duration;
        m = s / 60;
        s = s % 60;
        h = m / 60;
        m = m % 60;
        string = [NSString stringWithFormat:@"%02d:%02d:%02d\n", h, m, s];
    }
    else {
        string = @"00:00:00\n";
    }
    richText = [self formatRichText:string font1:titleFont color1:titleClr title2:@"时长" font2:subFont color2:subClr];
    [_lblDuration setAttributedText:richText];

    int calorie;
    if(workout != nil)
        calorie = (int)workout.summary.calorie;
    else
        calorie = 0;
    string = [NSString stringWithFormat:@"%d\n", calorie];
    richText = [self formatRichText:string font1:titleFont color1:titleClr title2:@"卡路里" font2:subFont color2:subClr];
    [_lblCalorie setAttributedText:richText];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailedHistoryMapTableCell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"detailedHistoryMapTableCell"];
        CGRect bounds = tableView.bounds;
        bounds.size.height = tableView.rowHeight;
        CGRect rc;

        rc.origin.x = 16;
        rc.origin.y = 0;
        rc.size.width = 56/2;
        rc.size.height = 56/2;
        rc.origin.y = bounds.size.height/2 - rc.size.height/2;
        UIImageView *v = [[UIImageView alloc] initWithFrame:rc];
        v.tag = 1;
        [cell.contentView addSubview:v];
        
        rc.origin.x = rc.origin.x + rc.size.width + 8;
        rc.size.width = 256 * rate_pixel_to_point;
        UILabel *lbl = [[UILabel alloc] initWithFrame:rc];
        lbl.font = [UIFont systemFontOfSize:20*2*rate_pixel_to_point];
        lbl.textColor = [UIColor colorWithRed:0x24/255.0 green:0x25/255.0 blue:0x2a/255.0 alpha:0.75];
        lbl.tag = 2;
        [cell.contentView addSubview:lbl];
        
        rc.origin.x = rc.origin.x + rc.size.width;
        rc.size.width = bounds.size.width - rc.origin.x - 24;
        UILabel *lblVal = [[UILabel alloc] initWithFrame:rc];
        lblVal.textAlignment = NSTextAlignmentRight;
        lblVal.tag = 3;
        [cell.contentView addSubview:lblVal];

        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    UIImageView *icon = (UIImageView *)[cell.contentView viewWithTag:1];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:2];
    UILabel *value = (UILabel *)[cell.contentView viewWithTag:3];
    switch(indexPath.row) {
        case 0:
            icon.image = [UIImage imageNamed:@"history_icon_03.png"];
            title.text = @"平均配速";

            if(_workout != nil) {
                NSUInteger pace = _workout.summary.avgPace;
                NSUInteger minutes = pace / 60;
                NSUInteger seconds = pace % 60;
                NSString *sPace = [NSString stringWithFormat:@"%02d:%02d ",(unsigned int)minutes,(unsigned int)seconds];
                NSMutableAttributedString *attribTitle = [self formatText:sPace subTitle:@"分钟/公里"];
                [value setAttributedText:attribTitle];
            }
            break;
        case 1:
            icon.image = [UIImage imageNamed:@"history_icon_06.png"];
            title.text = @"平均速度";

            if(_workout != nil) {
                NSUInteger pace = _workout.summary.avgPace;
                float speed = pace > 0 ? 3600.0 / pace : 0;
                NSString *sSpeed = [NSString stringWithFormat:@"%.1f ",speed];
                NSMutableAttributedString *attribTitle = [self formatText:sSpeed subTitle:@"公里/小时"];
                [value setAttributedText:attribTitle];
            }
            break;
        case 2:
            icon.image = [UIImage imageNamed:@"history_icon_08.png"];
            title.text = @"最高速度";

            if(_workout != nil) {
                NSUInteger pace = _workout.summary.maxPace;
                float speed = pace > 0 ? 3600.0 / pace : 0;
                NSString *sSpeed = [NSString stringWithFormat:@"%.1f ",speed];
                NSMutableAttributedString *attribTitle = [self formatText:sSpeed subTitle:@"公里/小时"];
                [value setAttributedText:attribTitle];
            }
            break;
        case 3:
            icon.image = [UIImage imageNamed:@"history_icon_10.png"];
            title.text = @"海拔上升";

            if(_workout != nil) {
                NSUInteger up = _workout.summary.altitudeUp - _workout.summary.altitudeDown;
                NSString *sUp = [NSString stringWithFormat:@"%d ", (int)up];
                NSMutableAttributedString *attribTitle = [self formatText:sUp subTitle:@"米"];
                [value setAttributedText:attribTitle];
            }
            break;
        default:
            return nil;
            break;
    }
    
    return cell;
}

- (NSMutableAttributedString *) formatText:(NSString *)title subTitle:(NSString *)sub
{
    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:24*2*rate_pixel_to_point];
    if(titleFont == nil)
        titleFont = [UIFont systemFontOfSize:24*2*rate_pixel_to_point];
    UIFont *subFont = [UIFont systemFontOfSize:16*2*rate_pixel_to_point];

    UIColor *clrCapNormal = [UIColor colorWithRed:0x1f/255.0 green:0x20/255.0 blue:0x25/255.0 alpha:1.0];
    UIColor *clrSub = [UIColor colorWithRed:0x24/255.0 green:0x25/255.0 blue:0x2a/255.0 alpha:0.75];

    NSMutableAttributedString *richText = [self formatRichText:title font1:titleFont color1:clrCapNormal title2:sub font2:subFont color2:clrSub];
    
    return richText;
}

- (NSMutableAttributedString *) formatRichText:(NSString *)title1 font1:(UIFont *)font1 color1:(UIColor *)clr1 title2:(NSString *)title2 font2:(UIFont *)font2 color2:(UIColor *)clr2
{
    NSDictionary *attrDict1 = @{ NSFontAttributeName: font1,
                                 NSForegroundColorAttributeName:clr1};
    NSAttributedString *attrStr1 = [[NSAttributedString alloc] initWithString:title1 attributes: attrDict1];
    
    //第二段
    NSDictionary *attrDict2 = @{ NSFontAttributeName: font2,
                                 NSForegroundColorAttributeName:clr2};
    NSAttributedString *attrStr2 = [[NSAttributedString alloc] initWithString:title2 attributes: attrDict2];
    
    //合并
    NSMutableAttributedString *attributedStr03 = [[NSMutableAttributedString alloc] initWithAttributedString: attrStr1];
    [attributedStr03 appendAttributedString: attrStr2];
    
    return attributedStr03;
}

@end
