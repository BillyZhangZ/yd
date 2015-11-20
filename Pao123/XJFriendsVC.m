//
//  XJFriendsVC.m
//  Pao123
//
//  Created by 张志阳 on 15/6/29.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//
#import "config.h"
#import "XJFriendsVC.h"
#import "AppDelegate.h"
#import "XJFriends.h"
#import "XJAddFriendsVC.h"
#import "XJFriendInfoVC.h"
#import "XJNewFriendsVC.h"
#import "JSBadgeView.h"

@interface XJFriendsVC ()<UITableViewDataSource, UITableViewDelegate,UIGestureRecognizerDelegate,PullTableViewDelegate>
{
    NSInteger _applyFriendCount;
    NSInteger _friendsCount;
    NSMutableArray *_applyFriends;
    NSMutableArray *_friends;
}
@property (weak)XJAccount *myAccout;
@property (weak)XJAccountManager *accountManager;
@end

@implementation XJFriendsVC
-(instancetype)init
{
    self = [super init];
    if (self) {
        _applyFriendCount = 0;
        _friendsCount = 0;
        _applyFriends = [[NSMutableArray alloc]init];
        _friends = [[NSMutableArray alloc]init];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.pullArrowImage = [UIImage imageNamed:@"blackArrow"];
    self.tableView.pullBackgroundColor = [UIColor yellowColor];
    self.tableView.pullTextColor = [UIColor blackColor];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];

    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
    NSLog(@"friend dealloc");
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    _accountManager = app.accountManager;
    _myAccout = app.accountManager.currentAccount;
    [self.tableView reloadData];
    [self updateFriendList];
    //[self classifyFriends];
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)updateFriendList
{
    [_myAccout getFriendList:^(BOOL ok){
        [_myAccout getApplyFriendList:^(BOOL ok){
            [_accountManager storeAccountInfoToDisk];
            __block XJFriendsVC *blockSelf = self;
            [blockSelf classifyFriends];
        }];
        
    }];
}

-(void)classifyFriends
{
    [_applyFriends removeAllObjects];
    [_friends removeAllObjects];
    for (XJFriends *friend in _myAccout.friends) {
        if (friend.pendingState == STATE_WAIT_FOR_APPROVE) {
            [_applyFriends addObject:friend];
        }
        else [_friends addObject:friend];
    }
    _applyFriendCount = [_applyFriends count];
    _friendsCount = [_friends count];
    self.tableView.pullTableIsRefreshing = NO;
    [self.tableView reloadData];

}
#pragma mark - UITableView DataSource Delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //个数为姓氏首字母相同的所有好友
    if (section == 0 ) {
        return 1;
    }
    if (section == 1) {
        return _friendsCount;
    }
    return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}
#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendWorkoutTableCell"];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"friendWorkoutTableCell"];
    [JSBadgeView removeBadgeValue:cell.textLabel];
    if (indexPath.section == 0) {
        cell.textLabel.text = @"请求";
        cell.detailTextLabel.text =@"";
       // cell.imageView.image = [UIImage imageNamed:@"phoneAddress.png"];
        if (_applyFriendCount) {
            [JSBadgeView addBadgeViewTo:cell.textLabel withBadgeValue:[NSString stringWithFormat:@"%ld",(long)_applyFriendCount]];
        }
        cell.backgroundColor = [UIColor colorWithRed:34/255.0 green:34/255.0 blue:43/255.0 alpha:0.8];
    }
    else if (indexPath.section == 1) {
#pragma fix me nickname name image maybe nil, resulting crash
        
        NSString *nickName = [(XJFriends *)[_friends objectAtIndex:indexPath.row]  nickName];
        if ((NSNull *)nickName == [NSNull null]) {
            nickName = @"这个小子没有昵称";
        }
        cell.textLabel.text = nickName;
        cell.detailTextLabel.text = @"";
        cell.backgroundColor = [UIColor clearColor];
    }
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"item %ld selected", (long)indexPath.row);
    if (indexPath.section == 0) {
        if (_applyFriendCount) {
            _applyFriendCount = 0;
            [JSBadgeView removeBadgeValue:cell.textLabel];
        }

        XJNewFriendsVC *vc = [[XJNewFriendsVC alloc]initWithApplyFriendList:_applyFriends];
        [self presentViewController:vc animated:NO completion:nil];
    }
    else
    {
        XJFriendInfoVC *vc = [[XJFriendInfoVC alloc]init];
        vc.myself = [_myAccout.friends objectAtIndex:indexPath.row];
        [self presentViewController:vc animated:NO completion:nil];
    }
    [self performSelector:@selector(dummy) withObject:nil];
}

-(void)dummy
{
    
}

- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    NSLog(@"friend: refresh");
    [self updateFriendList];
}

#pragma mark - menu button clicked
- (IBAction)menuButtonClicked:(id)sender {
    DEBUG_ENTER;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    [delegate showMenu];
    DEBUG_LEAVE;
}
#pragma mark - add button clicked

- (IBAction)addButtonClicked:(id)sender
{
    XJAddFriendsVC *vc = [[XJAddFriendsVC alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
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
