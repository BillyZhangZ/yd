//
//  XJSMSLoginVerifyViewController.h
//  Pao123
//
//  Created by 张志阳 on 15/6/28.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XJSMSLoginViewController.h"
@interface XJSMSLoginVerifyViewController : UIViewController<UITextFieldDelegate, UIGestureRecognizerDelegate,UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *verifyTextFiled;
@property (weak, nonatomic) IBOutlet UIButton *verifyButton;
@property NSString *phoneNumber;
@end
