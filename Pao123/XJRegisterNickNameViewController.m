//
//  XJRegisterNickNameViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJRegisterNickNameViewController.h"
#import "config.h"
#import "AppDelegate.h"


@interface XJRegisterNickNameViewController ()
{
    NSInteger _userId;
    NSString *_userName;
    bool    _sex;
}
@property (nonatomic, weak)XJAccountManager *accountManager;
@end

@implementation XJRegisterNickNameViewController
-(instancetype)init:(NSInteger)userId userName:(NSString *)name
{
    self = [super init];
    if (self) {
        _userId = userId;
        _userName = name;
        _sex = FEMALE;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];

    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    AppDelegate * app = [[UIApplication sharedApplication]delegate];
    _accountManager = app.accountManager;
}
-(void)dealloc
{
    NSLog(@"register nickname dealloc");
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

- (IBAction)confirmButtonClicked:(id)sender {
    if ([self.nickName.text length] > 0) {
        
        NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_UPDATE_USER_INFO];
        [urlPost appendFormat:@"%lu",(unsigned long)_userId];
        NSURL *url = [NSURL URLWithString:urlPost];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        [request setHTTPMethod:@"POST"];
#pragma mark fix me register date should be get from server?
        NSString *string = [[NSString alloc] initWithFormat:@"nickname=%@&registerdate=%@&gender=%ld",self.nickName.text, stringFromDate([NSDate date]),(long)_sex];
        [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
        
        [request setTimeoutInterval:10.0f];
        
        void (^onDone)(NSData *data) = ^(NSData *data) {
            __block XJRegisterNickNameViewController * blockSelf = self;
            if(data == nil)
            {
                NSLog(@"Register nickname: remote server return nil");
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"昵称注册失败" message:@"请再试一下下" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
                [alert show];
                return;
            }
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if (dict == nil || [dict objectForKey:@"id"] == 0) {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"昵称注册失败" message:@"请再试一下下" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
                [alert show];
            }
            if ([_accountManager logIn:_userName userId:_userId]) {
                _accountManager.currentAccount.nickName = self.nickName.text;
                _accountManager.currentAccount.sex = _sex;
#pragma mark fix me register date should be get from server?
                _accountManager.currentAccount.registerdate = [NSDate date];
                [_accountManager storeAccountInfoToDisk];
                
                [blockSelf Complete];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"昵称注册失败" message:@"陛下再试一下下" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
                [alert show];
            }
        };
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if(error == nil && data != nil) {
                                       onDone(data);
                                   }
                                   else {
                                       onDone(nil);
                                   }
                               }];

            }
}

-(void)Complete
{
    __block XJRegisterNickNameViewController *blockSelf = self;
    //nick
    [blockSelf dismissViewControllerAnimated:NO completion:nil];
    //verify vc
    [blockSelf.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    //register vc
    [blockSelf.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];

    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app jumpToMainVC];
}
- (IBAction)maleButtonClicked:(id)sender {
    _sex = MALE;
    [self.maleButton setBackgroundColor:[UIColor colorWithRed:0xf0/255.0 green:0x65/255.0 blue:0x22/255.0 alpha:1.0]];
    [self.famaleButton setBackgroundColor:[UIColor clearColor]];
}
- (IBAction)femalButtonClicked:(id)sender {
    _sex = FEMALE;
    [self.famaleButton setBackgroundColor:[UIColor colorWithRed:0xf0/255.0 green:0x65/255.0 blue:0x22/255.0 alpha:1.0]];
    [self.maleButton setBackgroundColor:[UIColor clearColor]];
}

@end
