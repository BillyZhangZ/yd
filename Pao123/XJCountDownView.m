//
//  XJCountDownView.m
//  Pao123
//
//  Created by Zhenyong Chen on 5/30/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "AppDelegate.h"
#import "XJCountDownView.h"

@interface XJCountDownView () <UIGestureRecognizerDelegate>
{
    UILabel* _lblCountDown; // show remaining seconds
    UIButton *_btnAddTenSeconds;
    NSInteger _totalCount;
}
@end

@implementation XJCountDownView

- (instancetype) initWithFrame:(CGRect)Frame
{
    self = [super initWithFrame:Frame];
    
    if(self)
    {
        // 3 seconds by default
        _totalCount = 3;

        self.backgroundColor = [UIColor blackColor];

        CGRect rc = self.bounds;
        rc.origin.x = rc.size.width / 4;
        rc.origin.y = rc.size.height / 4;
        rc.size.width /= 2; // divided by 2 (amination will scale it)
        rc.size.height /= 2;
        
        _lblCountDown = [[UILabel alloc] initWithFrame:rc];
        _lblCountDown.textColor = [UIColor whiteColor];
        _lblCountDown.font = [UIFont boldSystemFontOfSize:50];
        _lblCountDown.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblCountDown];

        [self countDown];
    }
    
    return self;
}

- (void) countDown
{
    // display current seconds with animation
    if(_totalCount <= 0)
    {
        [self onCountDownFinished];

        return;
    }

    _lblCountDown.text = [NSString stringWithFormat:@"%ld", (long)_totalCount];

    _totalCount--;
    [UIView animateWithDuration:1.0
                          delay:0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         _lblCountDown.transform = CGAffineTransformMakeScale(2.0, 2.0);
                     }
                     completion:^(BOOL finished) {
                         _lblCountDown.transform = CGAffineTransformIdentity;
                         [self countDown];
                     }
     ];
}

- (void) onCountDownFinished
{
    // prevent reentrant
    if(self.superview == nil)
        return;

    _totalCount = 0;

    // remove from view stack
    [self removeFromSuperview];
    
    // change state (FIXME! move it to XJGoVC)
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJStdWorkout *wo = [app getCurrentWorkout];
    wo.state = XJWS_RUNNING;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
