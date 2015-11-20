//
//  XJRealplayVC.h
//  Pao123
//
//  Created by Zhenyong Chen on 6/28/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJRealplayVC : UIViewController

// Must set users BEFORE VC is going to load
@property (nonatomic) NSArray *userIDs;
@property (nonatomic) BOOL alwaysFirstRunnerVisible;

@end
