//
//  MainPanelView.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/16/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJStdWorkout.h"

@interface MainPanelView : UIView

@property (nonatomic) UIButton *btnSetVoice;
@property (nonatomic, readonly) char *btnLayout;

@property (nonatomic) UILabel *btnPause;
@property (nonatomic) UIButton *btnResume;
@property (nonatomic) UIButton *btnFinish;

- (void) update:(XJStdWorkout *)wo;
- (void) update:(XJStdWorkout *)wo eventFlag:(unsigned long long)flag;

@end
