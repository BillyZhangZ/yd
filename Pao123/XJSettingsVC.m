//
//  XJSettingsVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/13/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJSettingsVC.h"

@interface XJSettingsVC ()<UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource>
{
    UIImageView *_ivPhoto;
    UILabel *_lblNickName;
    UITableView *_tblOptions;
}
@end

@implementation XJSettingsVC

- (void)viewDidLoad {
    DEBUG_ENTER;
    [super viewDidLoad];
    
    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
    
    CGRect rc;
    rc = [[UIScreen mainScreen] bounds];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:rc];
    iv.image = [UIImage imageNamed:@"bg.png"];
    [self.view addSubview:iv];
//    iv = [[UIImageView alloc] initWithFrame:rc];
//    iv.image = [UIImage imageNamed:@"history_bg.png"];
//    [self.view addSubview:iv];
    
    // Do any additional setup after loading the view.
    self.vcTitle = @"设置";
    self.leftButtonImage = @"menu.png";
    [super constructView];
    [self.leftButton addTarget:self action:@selector(onBtnMenu) forControlEvents:UIControlEventTouchUpInside];

    int x = (lo_settings_icon_x_center_offset - lo_settings_icon_size / 2) * rate_pixel_to_point;
    int y = (lo_settings_icon_y_center_offset - lo_settings_icon_size / 2) * rate_pixel_to_point;
    rc = CGRectMake(x, y, lo_settings_icon_size*rate_pixel_to_point, lo_settings_icon_size*rate_pixel_to_point);
    _ivPhoto = [[UIImageView alloc] initWithFrame:rc];
    _ivPhoto.image = [UIImage imageNamed:@"user.png"];
    _ivPhoto.layer.cornerRadius = rc.size.width/2;
    _ivPhoto.layer.masksToBounds=YES;
    [self.view addSubview:_ivPhoto];

    rc.origin.x += rc.size.width + 16;
    rc.size.width = [[UIScreen mainScreen] bounds].size.width - rc.origin.x;
    _lblNickName = [[UILabel alloc] initWithFrame:rc];
    [_lblNickName setText:@"穿越时空的小碎步 >"];
    _lblNickName.font = [UIFont systemFontOfSize:SETTINGS_NICKNAME_FONT_SIZE];
    _lblNickName.textColor = [UIColor whiteColor];
    [self.view addSubview:_lblNickName];

    rc.origin.x = 0;
    rc.origin.y = lo_settings_table_y_offset * rate_pixel_to_point;
    rc.size.width = self.clientRect.size.width;
    rc.size.height = self.clientRect.size.height + self.clientRect.origin.y - rc.origin.y;
    _tblOptions = [[UITableView alloc] initWithFrame:rc style:UITableViewStyleGrouped];
    _tblOptions.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    _tblOptions.delegate = self;
    _tblOptions.dataSource = self;
    [_tblOptions setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tblOptions.frame = rc;
    [self.view addSubview:_tblOptions];

    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapHandle:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    DEBUG_LEAVE;
}

- (void)didReceiveMemoryWarning {
    DEBUG_ENTER;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DEBUG_LEAVE;
}

- (void) onBtnMenu
{
    DEBUG_ENTER;
    [_lblNickName resignFirstResponder];
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate showMenu];
    DEBUG_LEAVE;
}

-(void) switchAutoPause:(id)sender
{
    DEBUG_ENTER;
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    XJAccountManager *am = app.accountManager;
    UISwitch *s = (UISwitch *)sender;
    am.currentAccount.autoPause = s.on;
    DEBUG_LEAVE;
}

- (void) switchVoiceHelper:(id)sender
{
    DEBUG_ENTER;
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    XJAccountManager *am = app.accountManager;
    UISwitch *s = (UISwitch *)sender;
    am.currentAccount.voiceHelper = s.on;
    DEBUG_LEAVE;
}

-(void) switchNotification:(id)sender
{
    DEBUG_ENTER;
    UISwitch *s = (UISwitch *)sender;
    BOOL state = s.on;
    
    if (state) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    else
    {
        s.on =true;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法关闭通知" message:@"请到系统设置中关闭通知" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
         [alert show];
    }
    DEBUG_LEAVE;
}

- (void)handleGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    if(UIGestureRecognizerStateBegan == gesture.state ||
       UIGestureRecognizerStateChanged == gesture.state)
    {
        //根据被触摸手势的view计算得出坐标值
        CGPoint translation = [gesture translationInView:gesture.view];
        NSLog(@"%@", NSStringFromCGPoint(translation));
    }
    else
    {
        AppDelegate *app = [[UIApplication sharedApplication]delegate];
        [app showMenu];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
        return 2;
    else
        return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if(indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingTableCell1"];
        if(cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"settingTableCell1"];
        if(indexPath.row == 0) {
            cell.textLabel.text = @"设置通知";
            cell.detailTextLabel.text = @"来自系统的问候";
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, lo_settings_cell_switch_width*rate_pixel_to_point, lo_settings_cell_switch_height*rate_pixel_to_point)];
            switchView.tag = indexPath.row;
            cell.accessoryView = switchView;
            [switchView setOn:NO animated:NO];
            [switchView addTarget:self action:@selector(switchNotification:) forControlEvents:UIControlEventValueChanged];
            
            UIUserNotificationType types = [[[UIApplication sharedApplication] currentUserNotificationSettings] types];
            switchView.on = (types != UIUserNotificationTypeNone);
            switchView.onTintColor = DEFFGCOLOR;
        }
        else if(indexPath.row == 1) {
            cell.textLabel.text = @"语音助手";
            cell.detailTextLabel.text = @"嫌烦了，关掉它";
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, lo_settings_cell_switch_width*rate_pixel_to_point, lo_settings_cell_switch_height*rate_pixel_to_point)];
            switchView.tag = indexPath.row;
            cell.accessoryView = switchView;
            [switchView setOn:NO animated:NO];
            [switchView addTarget:self action:@selector(switchVoiceHelper:) forControlEvents:UIControlEventValueChanged];
            AppDelegate *app = [UIApplication sharedApplication].delegate;
            XJAccountManager *am = app.accountManager;
            switchView.on = am.currentAccount.voiceHelper;
            switchView.onTintColor = DEFFGCOLOR;
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingTableCell2"];
        if(cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingTableCell2"];
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"意见反馈";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case 1:
                cell.textLabel.text = @"关于123GO";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case 2:
                cell.textLabel.text = @"特别鸣谢";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            default:
                return nil;
        }
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:SETTINGS_CELL_TITLE_FONT_SIZE];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:SETTINGS_CELL_SUBTITLE_FONT_SIZE];
    [cell setBackgroundColor:[UIColor colorWithRed:1.0 green:0 blue:0 alpha:0]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if(indexPath.section == 0)
        return 192 * rate_pixel_to_point;
    else
        return 128 * rate_pixel_to_point;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(section == 0)
        return 22;
    else
        return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(section == 0) {
        UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
        view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
        return view;
    }
    else {
        return nil;
    }
}

#pragma mark - gesture response
-(void)tapHandle:(UITapGestureRecognizer *)tap
{
//    [_tfNickName resignFirstResponder];
}

-(void)versionButtonClicked:(UIButton *)sender
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    [sender setTitle:version forState:UIControlStateNormal];
}
@end
