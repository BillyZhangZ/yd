//
//  XJBaseNavVC.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/13/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJBaseNavVC : UIViewController

// client area (excludes navigation bar)
@property (nonatomic, readonly) CGRect clientRect;
@property (nonatomic) NSString *vcTitle;
@property (nonatomic, readonly) UIButton *leftButton;
@property (nonatomic) NSString *leftButtonImage;
@property (nonatomic, readonly) UIButton *rightButton;
@property (nonatomic) NSString *rightButtonImage;
@property (nonatomic) NSString *rightButtonTitle;

- (void) constructView;

@end
