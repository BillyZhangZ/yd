//
//  XJSMSRegisterVerifyViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//
#import "XJSMSRegisterVerifyViewController.h"
#import "XJRegisterNickNameViewController.h"
#import "AppDelegate.h"
#import "config.h"
#import "XJAccountManager.h"
#import <SMS_SDK/SMS_SDK.h>
#define TIME_OUT 60

@interface XJSMSRegisterVerifyViewController ()
{
    NSTimer *_timer;
    NSInteger _verifyTimeout;
}
@end

@implementation XJSMSRegisterVerifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.verifyButton setEnabled:NO];
    [self.verifyButton setTitle:@"60秒" forState:UIControlStateNormal];
    self.verifyButton.tintColor = [UIColor blackColor];
    self.verifyTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.verifyTextField.keyboardAppearance = UIKeyboardAppearanceLight;
    self.verifyTextField.textColor = [UIColor grayColor];
    self.verifyTextField.layer.borderColor = [[UIColor blackColor] CGColor];
    
    //[self.verifyTextField becomeFirstResponder];
    self.verifyTextField.text = @"请输入123456";
    [self startTimer];
    
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
    self.verifyTextField.textColor = [UIColor blackColor];
    textField.text = @"";
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField.text length] == 4) {
        [SMS_SDK commitVerifyCode:textField.text result:^(enum SMS_ResponseState state) {
            if (1==state)
            {
                NSLog(@"验证成功");
                AppDelegate *app = [[UIApplication sharedApplication    ]delegate];
                [app.accountManager registerWithMobilePhone:textField.text complete:^(BOOL ok, NSInteger userId)
                 {
                     if (ok) {
                         XJRegisterNickNameViewController *vc = [[XJRegisterNickNameViewController alloc]init:userId userName:textField.text];
                         [self presentViewController:vc animated:NO completion:nil];
                     }
                     else
                     {
                    
                     }
                 }];
            }
            else if(0==state)
            {
                NSLog(@"验证失败");
            }
        }];
    }
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.verifyTextField) {
        NSInteger strLength = textField.text.length - range.length + string.length;
        if (strLength > 4){
            return NO;
        }
        NSString *text = nil;
        if (string.length > 0) {
            text = [NSString stringWithFormat:@"%@%@",textField.text,string];
        }else{
            text = [textField.text substringToIndex:range.location];
        }
        if (strLength == 4) {
            [self performSelector:@selector(delayResignResponsor) withObject:self afterDelay:0.3];
        }
    }
    return YES;
}
-(void)delayResignResponsor
{
    [self.verifyTextField resignFirstResponder];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        self.verifyTextField.text = @"";
    }
}

- (IBAction)verifyButtonClicked:(id)sender {
    
    //send request to server for sms
    UIButton *button = (UIButton *)sender;
    [button setEnabled:NO];
    [self startTimer];
    [button setTitle: [NSString stringWithFormat:@"%ld秒", (long)_verifyTimeout]  forState:UIControlStateNormal];
    button.tintColor = [UIColor blackColor];
}

-(void)onTimer:(NSTimer *)timer
{
    //just for test
    if (_verifyTimeout-- == 0)
    {
        [self releaseTimer];
        [self.verifyButton setEnabled:YES];
        [self.verifyButton setTitle:@"重新获取验证码" forState:UIControlStateNormal];
        self.verifyButton.tintColor = [UIColor blackColor];
        
    }
    else
    {
        [self.verifyButton setTitle: [NSString stringWithFormat:@"%ld秒", (long)_verifyTimeout]  forState:UIControlStateNormal];
        self.verifyButton.tintColor = [UIColor blackColor];
        
    }
}

-(void)releaseTimer
{
    _verifyTimeout = TIME_OUT;
    [_timer invalidate];
    _timer = nil;
}
-(void)startTimer
{
    if (_timer == nil) {
        _timer =  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
        _verifyTimeout = TIME_OUT;
    }
}

- (IBAction)backButtonClicked:(id)sender {
    [self releaseTimer];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
@end
