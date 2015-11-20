//
//  MainPanelView.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/16/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "MainPanelView.h"

@interface MainPanelView ()
{
    UILabel *_lblGps;
    char _order[4]; // button map
    UIButton *_btnDistance;
    UIButton *_btnHeartRate;
    UIButton *_btnPace;
    UIButton *_btnDuration;

    UIImageView *_ivPause;
}
@end

@implementation MainPanelView


- (instancetype) initWithFrame:(CGRect)Frame
{
    self = [super initWithFrame:Frame];
    
    if(self)
    {
        _btnLayout = _order;
        [self loadView];
    }
    
    return self;
}

- (void) loadView
{
    //-----------------------------------------------------------------------------
    // background
    //-----------------------------------------------------------------------------
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    CGRect rc = rcScreen;
    CGFloat par = BACKGROUNDPIC_WIDTH / BACKGROUNDPIC_HEIGHT;
    CGFloat expectedHeight = rc.size.width / par;
    rc.size.height = expectedHeight;
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:rc];
    bgView.image = [UIImage imageNamed:@"bg.png"];
    [self addSubview: bgView];

    self.backgroundColor = DEFBKCOLOR;

    CGRect rcClient;
    if(self.frame.size.width == rcScreen.size.width && self.frame.size.height == rcScreen.size.height)
    {
        CGRect rcApp = [[UIScreen mainScreen] applicationFrame];
        int statusBarHeight = rcApp.origin.y;
        
        // configure status bar
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, statusBarHeight)];
        statusBarView.backgroundColor = STATUSBARTINTCOLOR;
        [self addSubview:statusBarView];
        
        rcClient = rcScreen;
        rcClient.origin.y += statusBarHeight;
        rcClient.size.height -= statusBarHeight;
    }
    else
    {
        rcClient = self.bounds;
    }
    
    // Data panel
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    char *btnOrder = app.accountManager.currentAccount.btnLayout;

    memcpy(_order, btnOrder, 4);

    {
        int x, y;
        UIButton *btn;
        
        // title bar
        x = 0;
        y = rcClient.origin.y;
        rc.origin.x = x;
        rc.origin.y = y;
        rc.size.height = TITLEBARHEIGHT;
        rc.size.width = self.bounds.size.width;
        UILabel *label = [[UILabel alloc] initWithFrame:rc];
        label.text = @"123Go!";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = DEFFGCOLOR;
        label.font = [UIFont fontWithName:NAVIGATIONBAR_TITLE_FONT_NAME size:NAVIGATIONBAR_TITLE_FONT_SIZE];
        [self addSubview:label];
        
        // voice helper
        rc.origin.x = 0;
        rc.size.width = NAVIGATIONBAR_LEFT_ICON_SIZE;
        rc.size.height = NAVIGATIONBAR_LEFT_ICON_SIZE;
        rc.origin.y = rc.origin.y + (TITLEBARHEIGHT - rc.size.height)/2;
        _btnSetVoice = [[UIButton alloc] initWithFrame:rc];
        [_btnSetVoice setBackgroundImage:[UIImage imageNamed:@"voice-on.png"] forState:UIControlStateSelected];
        [_btnSetVoice setBackgroundImage:[UIImage imageNamed:@"voice-off.png"] forState:UIControlStateNormal];
        [self addSubview:_btnSetVoice];
        
        // gps status
        rc.size.width = NAVIGATIONBAR_SIDE_FONT_SIZE * 5; // 5 chars
        x = self.bounds.size.width - rc.size.width;
        rc.origin.x = x;
        rc.origin.y = y;
        rc.size.height = TITLEBARHEIGHT;
        _lblGps = [[UILabel alloc] initWithFrame:rc];
        _lblGps.text = @"GPS: -";
        _lblGps.textColor = DEFFGCOLOR;
        _lblGps.adjustsFontSizeToFitWidth = YES;
        _lblGps.font = [UIFont boldSystemFontOfSize:NAVIGATIONBAR_SIDE_FONT_SIZE];
        
        [self addSubview:_lblGps];
        
        rc.size.width = FIRE_WIDTH;
        rc.size.height = FIRE_HEIGHT;
        rc.origin.x = (rcScreen.size.width - rc.size.width) / 2;
        rc.origin.y = FIRE_ABS_Y;
        UIImageView *fire = [[UIImageView alloc] initWithFrame:rc];
        fire.image = [UIImage imageNamed:@"fire.png"];
        [self addSubview:fire];
        
        // draw head
#define MARGIN 32
        rc.size.height = MAJORDATA_TITLE_FONT_SIZE;
        rc.size.width = rcScreen.size.width - MARGIN*2;
        rc.origin.x = MARGIN;
        rc.origin.y = MAJORDATA_TITLE_ABS_Y;
        btn = [[UIButton alloc] initWithFrame:rc];
        btn.titleLabel.numberOfLines = 2;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.tag = _order[3];
        [btn addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        switch(_order[3])
        {
            case 'h':
                _btnHeartRate = btn;
                break;
            case 'p':
                _btnPace = btn;
                break;
            case 'd':
                _btnDuration = btn;
                break;
            case 'l':
            default:
                _btnDistance = btn;
                break;
        }
        
        
        // draw left button
        rc.origin.x = 0;
        rc.origin.y = lo_go_minordata_abs_y * rate_pixel_to_point;
        rc.size.width = self.bounds.size.width / 3 - 1;
        rc.size.height = lo_go_minordata_height * rate_pixel_to_point;
        btn = [[UIButton alloc] initWithFrame:rc];
        btn.titleLabel.numberOfLines = 2;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.tag = _order[0];
        [btn addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        switch(_order[0])
        {
            case 'h':
                _btnHeartRate = btn;
                break;
            case 'p':
                _btnPace = btn;
                break;
            case 'd':
                _btnDuration = btn;
                break;
            case 'l':
            default:
                _btnDistance = btn;
                break;
        }
        
        // place a vertical bar
        rc.origin.x += rc.size.width;
        rc.size.width = 1;
        UIView *v = [[UIView alloc] initWithFrame:rc];
        v.backgroundColor = MINORDATA_SPLIT_COLOR;
        [self addSubview:v];
        
        // draw middle button
        rc.origin.x += rc.size.width;
        rc.size.width = self.bounds.size.width / 3 - 1;
        btn = [[UIButton alloc] initWithFrame:rc];
        btn.titleLabel.numberOfLines = 2;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.tag = _order[1];
        [btn addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        switch(_order[1])
        {
            case 'h':
                _btnHeartRate = btn;
                break;
            case 'p':
                _btnPace = btn;
                break;
            case 'd':
                _btnDuration = btn;
                break;
            case 'l':
            default:
                _btnDistance = btn;
                break;
        }
        
        // place a vertical bar
        rc.origin.x += rc.size.width;
        rc.size.width = 1;
        v = [[UIView alloc] initWithFrame:rc];
        v.backgroundColor = MINORDATA_SPLIT_COLOR;
        [self addSubview:v];
        
        // draw right button
        rc.origin.x += rc.size.width;
        rc.size.width = self.bounds.size.width - rc.origin.x;
        btn = [[UIButton alloc] initWithFrame:rc];
        btn.titleLabel.numberOfLines = 2;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.tag = _order[2];
        [btn addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        switch(_order[2])
        {
            case 'h':
                _btnHeartRate = btn;
                break;
            case 'p':
                _btnPace = btn;
                break;
            case 'd':
                _btnDuration = btn;
                break;
            case 'l':
            default:
                _btnDistance = btn;
                break;
        }
    }

    // Buttons
    int remainY = rcScreen.size.height - (rc.origin.y + rc.size.height);
    int offset = lo_go_pausebutton_center_y_to_bottom*rate_pixel_to_point;
    offset += lo_go_pausebutton_size/2;
    if(remainY >= offset + 20) {
        rc.size.width = rc.size.height = lo_go_pausebutton_size;
        rc.origin.x = (rcScreen.size.width - rc.size.width) / 2;
        rc.origin.y = (rcScreen.size.height - offset);
    }
    else {
        float d = rcScreen.size.width > remainY ? remainY : rcScreen.size.width;
        d /= 2;
        rc.size.width = rc.size.height = d - 32;
        rc.origin.x = (rcScreen.size.width - rc.size.width) / 2;
        rc.origin.y = (rcScreen.size.height - remainY/2 - rc.size.height/2);
    }
    _ivPause = [[UIImageView alloc] initWithFrame:rc];
    _ivPause.image = [UIImage imageNamed:@"pause.png"];
    
    _btnPause = [[UILabel alloc] initWithFrame:rc];
    _btnPause.userInteractionEnabled = YES;
//    [_btnPause  setImage:[UIImage imageNamed:@"wait.png"]];
    _btnPause.text = @"长按暂停";
    _btnPause.textColor = [UIColor whiteColor];
    _btnPause.font = [UIFont systemFontOfSize:lo_go_pausebutton_font_size * rate_pixel_to_point];
    _btnPause.textAlignment = NSTextAlignmentCenter;

    rc.size.width = rc.size.height = lo_go_resumebutton_size * rate_pixel_to_point;
    rc.origin.x = rcScreen.size.width/2 - rc.size.width/2;
    rc.origin.y = _btnPause.frame.origin.y + _btnPause.frame.size.height/2 - rc.size.height/2;
    _btnFinish = [[UIButton alloc] initWithFrame:rc];
    [_btnFinish setTitle:@"结束" forState:UIControlStateNormal];
    [_btnFinish setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnFinish.titleLabel.font = [UIFont systemFontOfSize:lo_go_resumebutton_font_size * rate_pixel_to_point];
    [_btnFinish setBackgroundColor:DEFFGCOLOR];
    _btnFinish.layer.cornerRadius = rc.size.width / 2;

    _btnResume = [[UIButton alloc] initWithFrame:rc];
    [_btnResume setTitle:@"继续" forState:UIControlStateNormal];
    [_btnResume setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnResume.titleLabel.font = [UIFont systemFontOfSize:lo_go_resumebutton_font_size * rate_pixel_to_point];
    [_btnResume setBackgroundColor:RESUME_BUTTON_BACKGROUND_COLOR];
    _btnResume.layer.cornerRadius = rc.size.width / 2;

    // inject data
    XJStdWorkout *wo = [app getCurrentWorkout];
    [self update:wo eventFlag:EF_UPDATE_ALL];
}

- (void) update:(XJStdWorkout *)wo
{
    if(wo.state == XJWS_RUNNING)
    {
        [self addSubview:_ivPause];
        [self addSubview:self.btnPause];
        [self.btnResume removeFromSuperview];
        [self.btnFinish removeFromSuperview];

        // restore to center position
        CGRect rcCenter = self.btnResume.frame;
        rcCenter.origin.x = self.bounds.size.width/2 - rcCenter.size.width/2;
        self.btnResume.frame = self.btnFinish.frame = rcCenter;
    }
    else if(wo.state == XJWS_PAUSED)
    {
        [_ivPause removeFromSuperview];
        [self.btnPause removeFromSuperview];

        CGRect rcResume = self.btnResume.frame;
        CGRect rcFinish = self.btnFinish.frame;
        rcResume.origin.x = self.bounds.size.width/2 + (lo_go_resume_finish_center_distance/2-lo_go_resumebutton_size/2)*rate_pixel_to_point;
        rcFinish.origin.x = self.bounds.size.width/2 - (lo_go_resume_finish_center_distance/2+lo_go_resumebutton_size/2)*rate_pixel_to_point;

        [self addSubview:self.btnResume];
        [self addSubview:self.btnFinish];

        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationRepeatAutoreverses:NO];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.window cache:YES];
        [UIView setAnimationDuration:0.7];
        self.btnResume.frame = rcResume;
        self.btnFinish.frame = rcFinish;
        [UIView commitAnimations];
    }

    [self update:wo eventFlag:EF_UPDATE_ALL];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/



- (void) onButtonClicked:(id)sender
{
    char tag = ((UIButton *)sender).tag;
    int i;
    for(i=0; i<4; i++)
    {
        if(_order[i] != tag)
            continue;
        
        if(i < 3)
        {
            // switch with _order[3]
            UIButton *src;
            switch(_order[i])
            {
                case 'h':
                    src = _btnHeartRate;
                    break;
                case 'p':
                    src = _btnPace;
                    break;
                case 'd':
                    src = _btnDuration;
                    break;
                case 'l':
                default:
                    src = _btnDistance;
                    break;
            }
            UIButton *dst;
            switch(_order[3])
            {
                case 'h':
                    dst = _btnHeartRate;
                    break;
                case 'p':
                    dst = _btnPace;
                    break;
                case 'd':
                    dst = _btnDuration;
                    break;
                case 'l':
                default:
                    dst = _btnDistance;
                    break;
            }
            
            char t = _order[i];
            _order[i] = _order[3];
            _order[3] = t;
            /*
             [UIView beginAnimations:nil context:nil];
             [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
             [UIView setAnimationRepeatAutoreverses:NO];
             [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.window cache:YES];
             [UIView setAnimationDuration:0.7];*/
            CGRect rc = src.frame;
            src.frame = dst.frame;
            dst.frame = rc;
            /*            [UIView commitAnimations];*/
            
            [self refreshButtonTitle:src];
            [self refreshButtonTitle:dst];
        }
        
        break;
    }
}

- (void) refreshButtonTitle:(UIButton *)btn
{
    NSString *title = btn.titleLabel.text;
    // get title and subtitle
    NSRange range = [title rangeOfString:@"\n"];
    NSUInteger i = range.location + range.length;
    NSString *title1 = [title substringToIndex:i];
    NSString *title2 = [title substringFromIndex:i];
    NSAttributedString *attribTitle;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    attribTitle = [delegate formatText:title1 subTitle:title2 isHead:[self isLargeButton:btn]];
    [btn setAttributedTitle:attribTitle forState:UIControlStateNormal];
}

- (BOOL) isLargeButton:(UIButton *)btn
{
    char tag = btn.tag;
    if(_order[3] == tag)
        return YES;
    else
        return NO;
}

- (void) update:(XJStdWorkout *)wo eventFlag:(unsigned long long)flag
{
    if(flag & EF_UPDATE_STATE)
    {
        // change timer state according to workout state
        if(wo.state == XJWS_CREATING)
        {
            AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            // clear values
            NSAttributedString *attribTitle;
            attribTitle = [delegate formatText:@"0.00\n" subTitle:@"距离 (公里)" isHead:[self isLargeButton:_btnDistance]];
            [_btnDistance setAttributedTitle:attribTitle forState:UIControlStateNormal];
            
            //    attribTitle = [delegate formatText:@"0\n" subTitle:@"卡路里" isHead:NO];
            attribTitle = [delegate formatText:@"--\n" subTitle:@"心率" isHead:[self isLargeButton:_btnHeartRate]];
            [_btnHeartRate setAttributedTitle:attribTitle forState:UIControlStateNormal];
            
            attribTitle = [delegate formatText:@"00:00\n" subTitle:@"配速 (分/公里)" isHead:[self isLargeButton:_btnPace]];
            [_btnPace setAttributedTitle:attribTitle forState:UIControlStateNormal];
            
            attribTitle = [delegate formatText:@"00:00\n" subTitle:@"时长" isHead:[self isLargeButton:_btnDuration]];
            [_btnDuration setAttributedTitle:attribTitle forState:UIControlStateNormal];
        }
    }
    
    if(flag & EF_UPDATE_LOCATION)
    {
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        // update all buttons
        NSString *length = [NSString stringWithFormat:@"%.2f\n",(float)wo.summary.length/1000];
        NSMutableAttributedString *attribTitle = [app formatText:length subTitle:@"距离 (公里)" isHead:[self isLargeButton:_btnDistance]];
        [_btnDistance setAttributedTitle:attribTitle forState:UIControlStateNormal];
        /*
         NSUInteger calories = [wo getCalorie:80];
         NSString *sCalories = [NSString stringWithFormat:@"%d\n",(int)calories];
         attribTitle = [delegate formatText:sCalories subTitle:@"卡路里" isHead:NO];
         [_btnLeft setAttributedTitle:attribTitle forState:UIControlStateNormal];*/
    }
    
    if(flag & EF_UPDATE_HEARTRATE)
    {
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        NSMutableAttributedString *attribTitle;
        
        if (wo.currentHeartRate.integerValue == 0)
            attribTitle = [app formatText:@"--\n" subTitle:@"心率" isHead:[self isLargeButton:_btnHeartRate]];
        else
            attribTitle = [app formatText:[NSString stringWithFormat:@"%@\n",wo.currentHeartRate] subTitle:@"心率" isHead:NO];
        [_btnHeartRate setAttributedTitle:attribTitle forState:UIControlStateNormal];
    }
    
    if(flag & EF_UPDATE_DURATION)
    {
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        
        NSTimeInterval intval = wo.summary.duration;
        int hour = (int)(intval/3600);
        int minute = (int)(intval - hour*3600)/60;
        int second = intval - hour*3600 - minute*60;
        NSString *dr = [NSString stringWithFormat:@"%02d:%02d:%02d\n", hour, minute,second];
        NSMutableAttributedString *attribTitle = [app formatText:dr subTitle:@"时长" isHead:[self isLargeButton:_btnDuration]];
        [_btnDuration setAttributedTitle:attribTitle forState:UIControlStateNormal];
        
        NSUInteger pace = [wo calcPace:[NSDate date]];
        NSUInteger minutes = pace / 60;
        NSUInteger seconds = pace % 60;
        NSString *sPace = [NSString stringWithFormat:@"%02d:%02d\n",(unsigned int)minutes,(unsigned int)seconds];
        attribTitle = [app formatText:sPace subTitle:@"配速 (分/公里)" isHead:[self isLargeButton:_btnPace]];
        [_btnPace setAttributedTitle:attribTitle forState:UIControlStateNormal];
        
        /*
         #define PACE_WALK (9*60+30) // 9'30''
         if(pace >= PACE_WALK || pace == 0)
         {
         [self onButtonClicked:_btnDistance];
         }
         else
         {
         [self onButtonClicked:_btnPace];
         }
         */
    }
    
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.btnSetVoice.selected = app.accountManager.currentAccount.voiceHelper;
    _lblGps.text = [NSString stringWithFormat:@"GPS: %@",gpsLevel(wo.summary.currentGpsStrength)];
}

@end
