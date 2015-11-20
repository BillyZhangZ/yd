//
//  XJDetailedHistoryMapView.h
//  Pao123
//
//  Created by 张志阳 on 15/6/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h> 
#import "XJWorkout.h"

#define SUMMARY_TABLEVIEW_TAG -1002

@interface XJDetailedHistoryMapView : UIView

- (void) loadWorkout:(XJWorkout *)workout;

@end
