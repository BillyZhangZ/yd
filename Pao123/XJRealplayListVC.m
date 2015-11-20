//
//  XJRealplayListVC.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/30/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJRealplayListVC.h"
#import "XJRealplayVC.h"
#import "model/XJFriends.h"

@interface XJRealplayListVC () <UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate>
{
    UITableView *_tblConnections;
    NSMutableArray *_items;
    NSMutableArray *_selectedUserIDs;
}
@end

@implementation XJRealplayListVC
-(instancetype)init
{
    self = [super init];
    if (self) {
        _selectedUserIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
    [self constructView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSUInteger i;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSArray *friends = delegate.accountManager.currentAccount.friends;
    _items = [[NSMutableArray alloc] init];
    for(i=0; i<friends.count; i++) {
        [_items addObject:[friends objectAtIndex:i]];
    }

#if defined(DEBUG)
    // add myself
    NSString *sMyName = delegate.accountManager.currentAccount.user;
    NSString *sMyNickName = delegate.accountManager.currentAccount.nickName;
    NSInteger sMyID = delegate.accountManager.currentAccount.userID;
    XJFriends *me = [[XJFriends alloc] initWithId:sMyID name:sMyName nickName:sMyNickName];
    [_items addObject:me];

    // add guest
    if(sMyID != 14) {
        // add guest as friend
        NSString *sName = @"游客";
        NSString *sNickName = @"到此一跑";
        XJFriends *usr = [[XJFriends alloc] initWithId:14 name:sName nickName:sNickName];
        [_items addObject:usr];
    }

    if(sMyID != 145) {
        // add guest as friend
        NSString *sName = @"志阳";
        NSString *sNickName = @"zhi yang";
        XJFriends *usr = [[XJFriends alloc] initWithId:145 name:sName nickName:sNickName];
        [_items addObject:usr];
    }
    if(sMyID != 147) {
        // add guest as friend
        NSString *sName = @"James 2";
        NSString *sNickName = @"James大牛";
        XJFriends *usr = [[XJFriends alloc] initWithId:147 name:sName nickName:sNickName];
        [_items addObject:usr];
    }
    if(sMyID != 132) {
        // add guest as friend
        NSString *sName = @"James 1";
        NSString *sNickName = @"James";
        XJFriends *usr = [[XJFriends alloc] initWithId:132 name:sName nickName:sNickName];
        [_items addObject:usr];
    }
    
    // add robots
    if(sMyID  != 120) {
        NSString *sName = @"测试1";
        NSString *sNickName = @"机器人2号";
        XJFriends *usr = [[XJFriends alloc] initWithId:120 name:sName nickName:sNickName];
        [_items addObject:usr];
    }

    if(sMyID != 10000) {
        NSString *sName = @"10000";
        NSString *sNickName = @"机器人1号";
        XJFriends *usr = [[XJFriends alloc] initWithId:10000 name:sName nickName:sNickName];
        [_items addObject:usr];
    }

#endif

    CGRect rc = _tblConnections.frame;
    rc.size.height = [_items count] * _tblConnections.rowHeight;
    if(rc.size.height > self.clientRect.size.height)
        rc.size.height = self.clientRect.size.height;
    _tblConnections.frame = rc;

    [_tblConnections reloadData];
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
    self.vcTitle = @"正在跑步的好友们";
    self.leftButtonImage = @"menu.png";
    self.rightButtonTitle = @"进入播放室";
    [super constructView];
    [self.leftButton addTarget:self action:@selector(onBtnMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.rightButton addTarget:self action:@selector(onBtnEnterRoom) forControlEvents:UIControlEventTouchUpInside];

    CGRect rc = self.clientRect;
    _tblConnections = [[UITableView alloc] initWithFrame:rc style:UITableViewStylePlain];
    _tblConnections.delegate = self;
    _tblConnections.dataSource = self;
    _tblConnections.separatorColor = [UIColor grayColor];
    _tblConnections.rowHeight = 50;
    [_tblConnections setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    _tblConnections.editing = NO;
    rc.size.height = [_items count] * _tblConnections.rowHeight;
    _tblConnections.frame = rc;
    [self.view addSubview:_tblConnections];
}

- (void) onBtnMenu
{
    DEBUG_ENTER;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate showMenu];
    DEBUG_LEAVE;
}

- (void) onBtnEnterRoom
{
    if(_selectedUserIDs.count == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请选择跑友"
                                                        message:@"忘了点一点？"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    XJRealplayVC *vc = [[XJRealplayVC alloc] init];
    vc.userIDs = _selectedUserIDs;
    [self presentViewController:vc animated:NO completion:^(void){}];
//    [self performSelector:@selector(dummy) withObject:nil];
}

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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"realplayTableCell"];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"realplayTableCell"];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    XJFriends *friend = [_items objectAtIndex:indexPath.row];
    NSMutableString *name = [[NSMutableString alloc] initWithString:@""];
    [name appendFormat:@"%@ (%@)", friend.nickName, friend.name];
    cell.textLabel.text = name;
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.textLabel.font = [UIFont fontWithName:@"Arial" size:12];
    if ([self idIsSelected:[NSString stringWithFormat:@"%ld", (unsigned long)friend.myId]]) {
        cell.imageView.image = [UIImage imageNamed:@"checkbox.png"];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"uncheckbox.png"];
    }
//    [cell.contentView setBackgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XJFriends *friend = [_items objectAtIndex:indexPath.row];
    if ([self idIsSelected:[NSString stringWithFormat:@"%ld", (unsigned long)friend.myId]]) {
        [_selectedUserIDs removeObject:[NSString stringWithFormat:@"%ld", (unsigned long)friend.myId]];
    }
    else {
        NSAssert(friend.myId != 0, @"Bad friend ID is selected");
        [_selectedUserIDs addObject:[NSString stringWithFormat:@"%ld", (unsigned long)friend.myId]];
    }
    [_tblConnections reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationFade];
}

- (void) dummy
{
}

- (BOOL) idIsSelected:(NSString *)usrID
{
    NSUInteger res = [_selectedUserIDs indexOfObject:usrID];
    if(res == NSNotFound)
        return NO;
    else
        return YES;
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
@end
