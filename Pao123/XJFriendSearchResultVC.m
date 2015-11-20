//
//  XJFriendSearchResultVC.m
//  Pao123
//
//  Created by 张志阳 on 15/7/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJFriendSearchResultVC.h"
#import "XJFriendsAddressBookCell.h"
#import "config.h"
#import "AppDelegate.h"
#import "XJFriends.h"
@interface XJFriendSearchResultVC ()<UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate>
{
    BOOL _cellRegistered;
}
@property (nonatomic) NSArray *searchResults;
@property (nonatomic, weak)XJAccount *myAccount;
@end

@implementation XJFriendSearchResultVC

-(instancetype)init:(NSArray *) searchResults;
{
    self =  [super init];
    if (self) {
        _searchResults = searchResults;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];

    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
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

}
-(void)dealloc
{
    NSLog(@"search friend result dealloc");
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


#pragma mark - UITableView DataSource Delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_searchResults count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}
#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_cellRegistered) {
        UINib *nib = [UINib nibWithNibName:@"XJFriendsAddressBookCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"addressBookCell"];
        _cellRegistered = true;
    }
    
    XJFriendsAddressBookCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addressBookCell"];
    if(cell == nil)
        cell = [[XJFriendsAddressBookCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"addressBookCell"];
    
    NSInteger userId = [[[_searchResults objectAtIndexedSubscript:indexPath.row] valueForKey:@"id"] integerValue];
    NSString *userName = [[_searchResults objectAtIndexedSubscript:indexPath.row] valueForKey:@"nickname"];
    
    cell.name.text = userName;
    [cell.status setEnabled:YES];
    //set to default
    [cell.status setTitle:@"添加" forState:UIControlStateNormal];
    [cell.status setBackgroundColor:[UIColor colorWithRed:0xf0/255.0 green:0x65/255.0 blue:0x22/255.0 alpha:1.0]];

    [cell.status addTarget:self action:@selector(addButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //[cell.status setBackgroundColor:[UIColor blueColor]];
    for (XJFriends *friend in _myAccount.friends) {
        if (friend.myId == userId ) {
            [cell.status setEnabled:NO];
            [cell.status setTitle:@"已添加" forState:UIControlStateNormal];
            [cell.status setBackgroundColor:[UIColor grayColor]];
        }
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


-(void)addButtonClicked:(id)sender
{
    NSLog(@"button clicked");
  
    UIButton *button = (UIButton *)sender;
    XJFriendsAddressBookCell *cell = (XJFriendsAddressBookCell *)[[button superview]superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *friend = [_searchResults objectAtIndex:indexPath.row];
    [button setEnabled:NO];

    [_myAccount addFriend:[[friend valueForKey:@"id"]integerValue] complete:^(bool ok){
        UIAlertView *alert;
        if (ok) {
            alert = [[UIAlertView alloc]initWithTitle:@"成功" message:@"等待对方同意" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [alert show];
             button.backgroundColor = [UIColor grayColor];
            [button setTitle:@"等待" forState:UIControlStateNormal];
        }
        else
        {
            alert = [[UIAlertView alloc]initWithTitle:@"失败" message:@"无法连接服务器或已申请" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [alert show];
            [button setEnabled:YES];
        }
        [self performSelector:@selector(dismissAlert:) withObject:alert afterDelay:1.0];
    }];
}

-(void)dismissAlert:(UIAlertView *)alert
{
    [alert dismissWithClickedButtonIndex:0 animated:YES];
}

- (IBAction)backButtonClicked:(id)sender {
    _searchResults = nil;
    [self dismissViewControllerAnimated:NO completion:nil];
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
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}
@end
