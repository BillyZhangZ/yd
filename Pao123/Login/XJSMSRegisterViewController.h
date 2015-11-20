//
//  XJSMSRegisterViewController.h
//  Pao123
//
//  Created by 张志阳 on 15/7/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XJSMSRegisterViewController : UIViewController<UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberText;

@end
