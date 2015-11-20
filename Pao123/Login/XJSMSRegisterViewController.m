//
//  XJSMSRegisterViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJSMSRegisterViewController.h"
#import "XJSMSRegisterViewController.h"
#import "XJSMSRegisterVerifyViewController.h"
#import "XJLoginVC.h"
#import "AppDelegate.h"
#import "config.h"
#import <SMS_SDK/SMS_SDK.h>
@interface XJSMSRegisterViewController ()<UIAlertViewDelegate>
{
    UIAlertView *_phoneNumberErrorAlert;
}
@end

@implementation XJSMSRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.phoneNumberText.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneNumberText.keyboardAppearance = UIKeyboardAppearanceLight;
    self.phoneNumberText.text = @"请输入您的手机号码";
    self.phoneNumberText.textColor = [UIColor grayColor];
    [self.phoneNumberText.layer setBorderColor:[UIColor redColor].CGColor];
       
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapHandle:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - disable landscape
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - TextField delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.textColor = [UIColor blackColor];
    textField.text = @"";
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyNext) {
        [textField resignFirstResponder];
    }
    return YES;
}
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([self isMobileNumber:textField.text]) {
        [SMS_SDK getVerificationCodeBySMSWithPhone:textField.text
                                              zone:@"86"
                                            result:^(SMS_SDKError *error)
         {
             if (!error)
             {
                 XJSMSRegisterVerifyViewController *vc = [[XJSMSRegisterVerifyViewController alloc]init];
                 vc.phoneNumber = textField.text;
                 [self presentViewController:vc animated:NO completion:nil];
             }
             else
             {
             }
             
         }];
    }else if([textField.text length] == 11){
        _phoneNumberErrorAlert =
        [[UIAlertView alloc]
         initWithTitle:@"对不起"
         message:[NSString stringWithFormat:@"请确认您的手机号码格式"]
         delegate:self
         cancelButtonTitle:@"确定"
         otherButtonTitles:nil, nil]
        ;
        [_phoneNumberErrorAlert show];
    }
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.phoneNumberText) {
        NSInteger strLength = textField.text.length - range.length + string.length;
        if (strLength > 11){
            return NO;
        }
        NSString *text = nil;
        //如果string为空，表示删除
        if (string.length > 0) {
            text = [NSString stringWithFormat:@"%@%@",textField.text,string];
        }else{
            text = [textField.text substringToIndex:range.location];
        }
        if (strLength == 11) {
            [self performSelector:@selector(delayResignResponsor) withObject:self afterDelay:0.3];
        }
    }
    return YES;
}

-(void)delayResignResponsor
{
    [self.phoneNumberText resignFirstResponder];
}

- (BOOL)isMobileNumber:(NSString *)mobileNum{
    NSString * MOBILE = MOBILE_PHONE_NUMBER;
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    if ([regextestmobile evaluateWithObject:mobileNum] == YES)
    {
        return YES;
    }else{
        return NO;
    }
}

#pragma mark - gesture response
-(void)tapHandle:(UITapGestureRecognizer *)tap
{
    [self.phoneNumberText resignFirstResponder];
}
- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == _phoneNumberErrorAlert) {
        if (buttonIndex == 0) {
            self.phoneNumberText.text  = @"";
        }
    }
}
@end
