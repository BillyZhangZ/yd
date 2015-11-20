//
//  XJDetailedHistorySegmentView.m
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJDetailedHistorySegmentView.h"

@interface XJDetailedHistorySegmentView () <UITableViewDelegate, UITableViewDataSource>
{
    UITableView *_segmentTableView;
    UILabel *_lblAvgPace;
    UILabel *_lblMaxPace;
    __weak XJWorkout *_workout;
}
@end

@implementation XJDetailedHistorySegmentView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        CGRect rc;
        rc = self.bounds;
        rc.size.width = rc.size.width / 2;
        rc.size.height = 210 * rate_pixel_to_point;
        _lblAvgPace = [[UILabel alloc] initWithFrame:rc];
        _lblAvgPace.backgroundColor = [UIColor colorWithRed:0x24/255.0 green:0x25/255.0 blue:0x2a/255.0 alpha:1.0];
        _lblAvgPace.numberOfLines = 2;
        _lblAvgPace.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblAvgPace];
        
        rc.origin.x += rc.size.width;
        _lblMaxPace = [[UILabel alloc] initWithFrame:rc];
        _lblMaxPace.backgroundColor = [UIColor colorWithRed:0x24/255.0 green:0x25/255.0 blue:0x2a/255.0 alpha:1.0];
        _lblMaxPace.numberOfLines = 2;
        _lblMaxPace.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblMaxPace];

        rc.size.width = self.bounds.size.width;
        rc.origin.x = 0;
        rc.origin.y = rc.origin.y + rc.size.height;
        rc.size.height = self.bounds.size.height - rc.origin.y;
        _segmentTableView = [[UITableView alloc]initWithFrame:rc style:UITableViewStyleGrouped  ];
        _segmentTableView.delegate = self;
        _segmentTableView.dataSource = self;
        _segmentTableView.rowHeight = 32;
        _segmentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _segmentTableView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_segmentTableView];
    }
    return self;
}

- (void) loadWorkout:(XJWorkout *)workout
{
    _workout = workout;
    
    NSAttributedString *richText;
    NSString *string;
    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.1*2*rate_pixel_to_point];
    if(titleFont == nil)
        titleFont = [UIFont systemFontOfSize:28.1*2*rate_pixel_to_point];
    UIFont *subFont = [UIFont systemFontOfSize:18*2*rate_pixel_to_point];
    UIColor *titleClr = [UIColor whiteColor];
    UIColor *subClr = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.75];

    int h, m, s;
    if(workout != nil) {
        s = (int)workout.summary.avgPace;
        m = s / 60;
        s = s % 60;
        h = m / 60;
        m = m % 60;
        if(h > 0)
            string = @"00\'00\"\n";
        else
            string = [NSString stringWithFormat:@"%2d\'%2d\"\n", m, s];
    }
    else {
        string = @"00\'00\"\n";
    }
    richText = [self formatRichText:string font1:titleFont color1:titleClr title2:@"平均配速" font2:subFont color2:subClr];
    [_lblAvgPace setAttributedText:richText];

    if(workout != nil) {
        s = (int)workout.summary.minPace;
        m = s / 60;
        s = s % 60;
        h = m / 60;
        m = m % 60;
        if(h > 0)
            string = @"00\'00\"\n";
        else
            string = [NSString stringWithFormat:@"%2d\'%2d\"\n", m, s];
    }
    else {
        string = @"00\'00\"\n";
    }
    richText = [self formatRichText:string font1:titleFont color1:titleClr title2:@"最快配速" font2:subFont color2:subClr];
    [_lblMaxPace setAttributedText:richText];

    [_segmentTableView reloadData];
}

- (int) validSplits:(XJWorkout *)workout
{
    if(workout == nil)
        return 0;
    int c = (int)workout.summary.splits.count;
    if(c == 0)
        return 0;
    XJSplit *last = workout.summary.splits.lastObject;
    if(last.distance < 1000)
        return c-1;
    else
        return c;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_workout == nil)
        return 0;
    
    int validCount = [self validSplits:_workout];

    int groups = (validCount + 4) / 5 + 1;
    int lastGroup = groups - 1;

    if(section == lastGroup) {
        return 0;
    }
    else if(section == lastGroup-1) {
        int remains = validCount % 5;
        return (remains == 0 ? 5 : remains);
    }
    else {
        return 5;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 36;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

#define COLUMN_KM_OFFSET_X 16
#define COLUMN_KM_WIDTH 48
#define COLUMN_HEART_REV_OFFSET_Y 16
#define COLUMN_HEART_WIDTH 48
#define DEFDATAFONT [UIFont fontWithName:@"HelveticaNeue-Light" size:16]
#define DEFDATAFONTL [UIFont fontWithName:@"HelveticaNeue-Light" size:12]
#define DEFDATAFONTCOLOR [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1.0]
#define SECTION_FONT_COLOR [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect rcSection = CGRectMake(0, 0, tableView.bounds.size.width, 36);
    UIView * sectionView = [[UIView alloc] initWithFrame:rcSection];

    if(section == 0) {
        CGRect rc = rcSection;
        rc.origin.x = COLUMN_KM_OFFSET_X;
        rc.size.width = COLUMN_KM_WIDTH;
        UILabel *lbl1 = [[UILabel alloc] initWithFrame:rc];
        lbl1.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24*2*rate_pixel_to_point];
        lbl1.textColor = SECTION_FONT_COLOR;
        lbl1.text = @"公里";
        lbl1.textAlignment = NSTextAlignmentLeft;
        [sectionView addSubview:lbl1];
        
        rc.origin.x += rc.size.width;
        rc.size.width = rcSection.size.width - rc.origin.x - (COLUMN_HEART_REV_OFFSET_Y + COLUMN_HEART_WIDTH);
        UILabel *lbl2 = [[UILabel alloc] initWithFrame:rc];
        lbl2.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24*2*rate_pixel_to_point];
        lbl2.textColor = SECTION_FONT_COLOR;
        lbl2.text = @"配速";
        lbl2.textAlignment = NSTextAlignmentLeft;
        [sectionView addSubview:lbl2];

        rc.origin.x = rcSection.size.width - COLUMN_HEART_REV_OFFSET_Y - COLUMN_HEART_WIDTH;
        rc.size.width = COLUMN_HEART_WIDTH;
        UILabel *lbl3 = [[UILabel alloc] initWithFrame:rc];
        lbl3.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24*2*rate_pixel_to_point];
        lbl3.textColor = SECTION_FONT_COLOR;
        lbl3.text = @"心率";
        lbl3.textAlignment = NSTextAlignmentLeft;
        [sectionView addSubview:lbl3];
    }
    else
    {
        CGRect rc = rcSection;
        rc.origin.x = COLUMN_KM_OFFSET_X;
        rc.size.width = 120;
        UILabel *lbl = [[UILabel alloc] initWithFrame:rc];
        lbl.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24*2*rate_pixel_to_point];
        lbl.textColor = SECTION_FONT_COLOR;
        int validCount = [self validSplits:_workout];
        int n;
        if(section*5 <= validCount)
            n = (int)section*5;
        else
            n = validCount;
        lbl.text = [NSString stringWithFormat:@"%d公里用时", n];
        lbl.textAlignment = NSTextAlignmentLeft;
        [sectionView addSubview:lbl];
        
        rc.size.width = 100;
        rc.origin.x = rcSection.size.width - rc.size.width;
        lbl = [[UILabel alloc] initWithFrame:rc];
        lbl.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24*2*rate_pixel_to_point];
        lbl.textColor = SECTION_FONT_COLOR;
        NSTimeInterval sum = 0;
        for(int i=0; i<n; i++) {
            XJSplit *split = [_workout.summary.splits objectAtIndex:i];
            if(split != nil)
                sum += split.duration;
        }
        int h, m, s;
        s = sum;
        m = s / 60;
        s = s % 60;
        h = m / 60;
        m = m % 60;
        NSString *string = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
        lbl.text = string;
        lbl.textAlignment = NSTextAlignmentLeft;
        [sectionView addSubview:lbl];
    }

    return sectionView;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(_workout == nil)
        return 0;

    int validCount = [self validSplits:_workout];

    int groups = (validCount + 4) / 5 + 1;
    return groups;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailedHistorySplitsTableCell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"detailedHistorySplitsTableCell"];
        CGRect bounds = tableView.bounds;
        bounds.size.height = tableView.rowHeight;
        CGRect rc;

        rc.origin.x = COLUMN_KM_OFFSET_X;
        rc.origin.y = 0;
        rc.size.width = COLUMN_KM_WIDTH;
        rc.size.height = bounds.size.height;
        UILabel *lbl;
        lbl = [[UILabel alloc] initWithFrame:rc];
        lbl.font = DEFDATAFONT;
        lbl.textColor = DEFDATAFONTCOLOR;
        lbl.tag = 1;
        [cell.contentView addSubview:lbl];

        rc.origin.y = 4;
        rc.origin.x += rc.size.width;
        rc.size.width = bounds.size.width - rc.origin.x - (COLUMN_HEART_REV_OFFSET_Y + COLUMN_HEART_WIDTH);
        rc.size.height = 16;
        lbl = [[UILabel alloc] initWithFrame:rc];
        lbl.font = DEFDATAFONTL;
        lbl.textColor = DEFDATAFONTCOLOR;
        lbl.tag = 2;
        [cell.contentView addSubview:lbl];

        rc.origin.y += rc.size.height;
        rc.size.height = 4;
        rc.size.width -= 16;
        UIView *v = [[UIView alloc] initWithFrame:rc];
        v.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
        v.tag = 3;
        [cell.contentView addSubview:v];

        rc.size.width = 0;
        v = [[UIView alloc] initWithFrame:rc];
        v.backgroundColor = DEFFGCOLOR;
        v.tag = 4;
        [cell.contentView addSubview:v];

        rc.origin.x = bounds.size.width - (COLUMN_HEART_REV_OFFSET_Y + COLUMN_HEART_WIDTH);
        rc.origin.y = 0;
        rc.size.width = (COLUMN_HEART_REV_OFFSET_Y + COLUMN_HEART_WIDTH);
        rc.size.height = bounds.size.height;
        lbl = [[UILabel alloc] initWithFrame:rc];
        lbl.font = DEFDATAFONT;
        lbl.textColor = DEFDATAFONTCOLOR;
//        lbl.textAlignment = NSTextAlignmentRight;
        lbl.tag = 5;
        [cell.contentView addSubview:lbl];
        
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    XJSplit *split = nil;
    if(indexPath.section*5+indexPath.row < _workout.summary.splits.count) {
        split = [_workout.summary.splits objectAtIndex:(indexPath.section*5+indexPath.row)];
    }
    if(split == nil)
        return nil;
    
    UILabel *lbl;
    lbl = (UILabel *)[cell.contentView viewWithTag:1];
    NSString *string;
    string = [NSString stringWithFormat:@"%d", (int)split.number+1];
    lbl.text = string;
    
    lbl = (UILabel *)[cell.contentView viewWithTag:2];
    int h, m, s;
    s = split.duration;
    m = s / 60;
    s = s % 60;
    h = m / 60;
    m = m % 60;
    if(h > 0)
        string = @"00\'00\"\n";
    else
        string = [NSString stringWithFormat:@"%2d\'%2d\"\n", m, s];
    lbl.text = string;
    
    UIView *v1 = (UIView *)[cell.contentView viewWithTag:3];
    UIView *v2 = (UIView *)[cell.contentView viewWithTag:4];
    // fill some color
    double rate = split.duration / (20*60);
    if(rate > 1)
        rate = 1;
    CGRect rc = v2.frame;
    rc.size.width = v1.frame.size.width * rate;
    v2.frame = rc;

    lbl = (UILabel *)[cell.contentView viewWithTag:5];
    string = [NSString stringWithFormat:@"%d", (int)split.heartRateAvg];
    lbl.text = string;

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
