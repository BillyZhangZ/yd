//
//  RunningListVC.m
//  Pao123
//
//  Created by 张志阳 on 15/7/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "RunningListVC.h"
#import "RunningListCell.h"
#import "AppDelegate.h"
#import "XJAccount.h"
#import "XJRunGroup.h"
#import "RunningDetailListVC.h"
@interface RunningListVC ()<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate,PullTableViewDelegate>
{
    BOOL _runningListCellRegistered;
    NSMutableArray *_activeRunGroups;
    
}
@property (weak)XJAccount *myAccount;
@end
@implementation RunningListVC

-(instancetype)init
{
    self = [super init];
    if (self) {
        _activeRunGroups = [[NSMutableArray alloc]init];
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
    //prepare pull-refresh table view
    self.tableView.pullArrowImage = [UIImage imageNamed:@"blackArrow"];
    self.tableView.pullBackgroundColor = [UIColor yellowColor];
    self.tableView.pullTextColor = [UIColor blackColor];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    _myAccount = app.accountManager.currentAccount;
    [_myAccount getFriendGroupFromServer:^(bool ok){
        NSLog(@"%ld", (long)ok);
        if(ok)
        {
            [_activeRunGroups removeAllObjects];
            for (XJRunGroup *group in _myAccount.runGroups) {
                if (group.activeMemberCount != 0) {
                    [_activeRunGroups addObject:group];
                }
            }
            [self.tableView reloadData];
        }
        else
        {
            UIAlertView *alert1 = [[UIAlertView alloc]initWithTitle:@"获取列表失败" message:@"服务器无响应" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert1 show];
        }
    }];
    _runningListCellRegistered = false;
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_activeRunGroups count];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect viewFrame = CGRectMake(0, 0, tableView.bounds.size.width, 20);
    UIView *view = [[UIView alloc]initWithFrame:viewFrame];
    view.backgroundColor= [UIColor colorWithRed:31/255.0 green:31/255.0 blue:34/255.0 alpha:1.0];
    return view;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20;
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RunningListCellIndentifier";
    if (!_runningListCellRegistered) {
        UINib *nib = [UINib nibWithNibName:@"RunningListCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"RunningListCellIndentifier"];
        _runningListCellRegistered = true;
    }
    RunningListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.name.text = [[_activeRunGroups objectAtIndex:indexPath.row] groupName];
    cell.count.text =[NSString stringWithFormat:@"%ld", (long)[[_activeRunGroups objectAtIndex:indexPath.row] activeMemberCount]];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RunningDetailListVC *vc = [[RunningDetailListVC alloc]initWithRunGroup:[_activeRunGroups objectAtIndex:indexPath.row]];
    [self presentViewController:vc animated:NO completion:nil];
    [self performSelector:@selector(dummy) withObject:nil];
}

-(void)dummy
{
    
}
#pragma mark - PullTableViewDelegate
//用户下拉列表触发，向网络同步数据, afterDalay后隐藏下拉动画, 提示用户会使用流量
- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    NSInteger networkStatus = app.networkStatus;
    
    if (networkStatus == 0) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"貌似无网络" message:@"请稍候再试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        self.tableView.pullTableIsRefreshing = NO;
        return;
    }
    [_myAccount getFriendGroupFromServer:^(bool ok){
        self.tableView.pullTableIsRefreshing = NO;
        NSLog(@"%ld", (long)ok);
        if(ok)
        {
            [_activeRunGroups removeAllObjects];
            for (XJRunGroup *group in _myAccount.runGroups) {
                if (group.activeMemberCount != 0) {
                    [_activeRunGroups addObject:group];
                }
            }
            [self.tableView reloadData];
        }
        else
        {
            UIAlertView *alert1 = [[UIAlertView alloc]initWithTitle:@"获取列表失败" message:@"服务器无响应" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert1 show];
        }
    }];
}


- (IBAction)backButtonClicked:(id)sender {
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app showMenu];
}


- (void)handleGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    if(UIGestureRecognizerStateBegan == gesture.state ||
       UIGestureRecognizerStateChanged == gesture.state)
    {
        //根据被触摸手势的view计算得出坐标值
        //CGPoint translation = [gesture translationInView:gesture.view];
        //NSLog(@"%@", NSStringFromCGPoint(translation));
    }
    else
    {
        AppDelegate *app = [[UIApplication sharedApplication]delegate];
        [app showMenu];
    }
}
@end
