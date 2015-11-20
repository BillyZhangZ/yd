//
//  AppDelegate.h
//  Pao123
//
//  Created by Chen Zhenyong on 24/5/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJWorkoutManager.h"
#import "XJAccountManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong) XJAccountManager *accountManager;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic)   UIImage *savedMapView;
@property (atomic)    NSInteger networkStatus;
@property (nonatomic)     NSString *devicePushId;
- (void) showMenu;
- (void) hideMenu;

-(void)jumpToMainVC;

- (void) onMenuItemClicked:(NSString *)itemName;

- (NSMutableAttributedString *) formatText:(NSString *)title subTitle:(NSString *)sub isHead:(BOOL)head;

// get a temp reference; do not cache it for later use!
- (XJStdWorkout *)getCurrentWorkout;
- (void) createNewWorkout;

//微信分享接口声明
- (void) sendTextContent: (NSString *)text withScene:(int)scene;
- (void) sendImageContent: (UIImage*)viewImage withScene:(int)scene;

// when run finished, delegate is resiponsible to navigate to history page
- (void) onRunFinished:(id)workout;

// debug method
- (void) XJLog:(NSString *)string;
- (void) simulateHeartRate:(BOOL)simu;

@end


UIViewController * findViewController(UIView *sourceView);
