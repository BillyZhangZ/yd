//
//  RunningDetailListVC.m
//  Pao123
//
//  Created by 张志阳 on 15/7/15.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "RunningDetailListVC.h"
#import "RunningDetailListCell.h"
#import "AppDelegate.h"
#import "XJRealplayVC.h"
@interface RunningDetailListVC ()<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
{
    NSMutableArray *_selectedUserIDs;
    NSMutableArray *_items;
    BOOL _runningDetailListCellRegistered;
}
@end

@implementation RunningDetailListVC
-(instancetype)initWithRunGroup:(XJRunGroup *)group;
{
    self = [super init];
    if (self) {
        self.runGroup = group;
        _selectedUserIDs = [[NSMutableArray alloc] init];

    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"view did load");
    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
    
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
    _runningDetailListCellRegistered = 0;
    NSLog(@"view will appear");
    [_selectedUserIDs removeAllObjects];
    [[_runGroup activeMembers] removeAllObjects];
    [_runGroup getActiveGroupMembers:^(bool ok){
        if (ok) {
            NSLog(@"get active member ok");
            _items = [[NSMutableArray alloc] init];
            for (XJFriends *friend in _runGroup.activeMembers) {
                [_items addObject:friend];
            }
            [self.tableView reloadData];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"获取列表失败" message:@"" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
    [self.tableView reloadData];
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
    if ([_runGroup activeMembers] != nil) {
        return [[_runGroup activeMembers] count];
    }
    return 0;
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
    return 0;
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RunningDetailListCellIdentifier";
    if (!_runningDetailListCellRegistered) {
        UINib *nib = [UINib nibWithNibName:@"RunningDetailListCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"RunningDetailListCellIdentifier"];
        _runningDetailListCellRegistered = true;
    }
    RunningDetailListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.portrait.image = [UIImage imageNamed:@"portrait.png"];
    cell.name.text = [[_runGroup.activeMembers objectAtIndex:indexPath.row] nickName];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    
    XJFriends *friend = [[_runGroup activeMembers]objectAtIndex:indexPath.row];
    if ([self idIsSelected:[NSString stringWithFormat:@"%ld", (unsigned long)friend.myId]]) {
        cell.checkImage.image = [UIImage imageNamed:@"check.png"];
    }
    else {
        cell.checkImage.image = [UIImage imageNamed:@"uncheck.png"];
    }
    cell.selectionStyle= UITableViewCellAccessoryNone;
    return cell;

}
- (BOOL) idIsSelected:(NSString *)usrID
{
    NSUInteger res = [_selectedUserIDs indexOfObject:usrID];
    if(res == NSNotFound)
        return NO;
    else
        return YES;
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
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationFade];

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
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}
- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}
- (IBAction)watchButtonClicked:(id)sender {
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
}
@end
