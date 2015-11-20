//
//  XJLoginVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/13/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJLoginVC.h"

#define INTERNAL_TEST

@interface XJLoginVC () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
    // Current User
    UIImageView *_ivPhoto;
    UILabel *_lblName;

#if defined(INTERNAL_TEST)
    UITableView *_tblUsersList;
    NSArray *_items;
#else
    UIButton *_btnWechatAccount;
#endif
}
@end

@implementation XJLoginVC

- (void)viewDidLoad {
    DEBUG_ENTER;
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self constructView];
    DEBUG_LEAVE;
}

- (void)didReceiveMemoryWarning {
    DEBUG_ENTER;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DEBUG_LEAVE;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) constructView
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJAccountManager *am = app.accountManager;
    self.vcTitle = @"登录123GO...";
    self.leftButtonImage = @"back.png";
    [super constructView];
    [self.leftButton addTarget:self action:@selector(onBtnBack) forControlEvents:UIControlEventTouchUpInside];
    
    CGPoint center = CGPointMake(self.clientRect.origin.x + self.clientRect.size.width / 2, self.clientRect.origin.y + self.clientRect.size.height / 2);

    CGRect rc;
    int y = self.clientRect.origin.y+50;
    rc = CGRectMake(center.x - TITLEBARHEIGHT, y, TITLEBARHEIGHT*2, TITLEBARHEIGHT*2);
    _ivPhoto = [[UIImageView alloc] initWithFrame:rc];
    _ivPhoto.image = [UIImage imageNamed:@"user.png"];
    _ivPhoto.layer.cornerRadius = TITLEBARHEIGHT;
    _ivPhoto.layer.masksToBounds = YES;
    [self.view addSubview:_ivPhoto];

    rc.origin.y += rc.size.height + 20;
    rc.origin.x = center.x - 100;
    rc.size.width = 200;
    rc.size.height = 60;
    _lblName = [[UILabel alloc] initWithFrame:rc];
    _lblName.text = am.currentAccount.user;
    _lblName.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_lblName];

#if defined(INTERNAL_TEST)
    rc.size.width = 400;
    rc.size.height = 200;
    rc.origin.x = center.x - rc.size.width/2;
    rc.origin.y = self.view.bounds.size.height - rc.size.height;
    
    _items = [[NSArray alloc] initWithObjects:@"Speer",@"志阳",@"晓俊", @"真勇", @"James", @"测试1", @"测试2", @"10000", @"退出", nil];
    _tblUsersList = [[UITableView alloc] initWithFrame:rc style:UITableViewStylePlain];
    _tblUsersList.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    _tblUsersList.delegate = self;
    _tblUsersList.dataSource = self;
    _tblUsersList.separatorColor = [UIColor grayColor];
    [_tblUsersList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tblUsersList.editing=NO;
    [self.view addSubview:_tblUsersList];
#else
    y = self.clientRect.size.height + self.clientRect.origin.y - TITLEBARHEIGHT - 150;
    rc.origin.x = center.x - 50;
    rc.origin.y = y;
    rc.size.width = 100;
    rc.size.height = TITLEBARHEIGHT;
    
    _btnWechatAccount = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnWechatAccount.frame = CGRectMake(rc.origin.x, rc.origin.y, 80, 80);
    [_btnWechatAccount setBackgroundImage:[UIImage imageNamed:@"wechat.png"] forState:UIControlStateNormal];
    [_btnWechatAccount addTarget:self action:@selector(onBtnCreateNewAccount) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnWechatAccount];
#endif
}

- (void) onBtnBack
{
    DEBUG_ENTER;
    [self dismissViewControllerAnimated:NO completion:^{}];
    DEBUG_LEAVE;
}

#if !defined(INTERNAL_TEST)
- (void) onBtnCreateNewAccount
{
}
#endif

- (void) update
{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJAccountManager *am = app.accountManager;
    _lblName.text = am.currentAccount.user;
}

#if defined(INTERNAL_TEST)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"menuTableCell"];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"menuTableCell"];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = [_items objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"Arial" size:12];
    cell.imageView.image = [UIImage imageNamed:@"user.png"];
    [cell.contentView setBackgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *itemName = [_items objectAtIndex:indexPath.row];
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    XJAccountManager *am = app.accountManager;

    // pop up a waiting dialog and dismiss it when verification done
    
    UIAlertView *alert = [self showWaitingAlert];

    void (^onDone)(BOOL ok) = ^(BOOL ok) {
        [self dismissWaitingAlert:alert];
        if(ok) {
            [self update];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"登录失败" message:@"检查网络或者用户名是否正确" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
    };
    [am logIn:([itemName compare:@"退出"] == NSOrderedSame) name:itemName complete:onDone];
}

#endif

- (UIAlertView *) showWaitingAlert
{
    UIAlertView *waittingAlert = [[UIAlertView alloc] initWithTitle: @"正在认证"
                                                            message: @"请稍候..."
                                                           delegate: nil
                                                  cancelButtonTitle: nil
                                                  otherButtonTitles: nil];
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.frame = CGRectMake(139.0f-18.0f, 80.0f, 37.0f, 37.0f);
    [waittingAlert addSubview:activityView];
    [activityView startAnimating];

    [waittingAlert show];

    return waittingAlert;
}

- (void) dismissWaitingAlert:(UIAlertView *) waittingAlert
{
    if (waittingAlert != nil)
    {
        [waittingAlert dismissWithClickedButtonIndex:0 animated:YES];
        waittingAlert =nil;
    }
}
@end
