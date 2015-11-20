//
//  XJFriendGroupSearchViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//
#import "config.h"
#import  "AppDelegate.h"
#import "XJFriendGroupSearchViewController.h"
#import "XJFriendGroupCell3.h"
#import "XJRunGroup.h"
@interface XJFriendGroupSearchViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,UIGestureRecognizerDelegate>
{
    BOOL _friendGroupCell3Registered;
}
@property (nonatomic,weak) XJAccount *myAccount;
@property (nonatomic) NSMutableArray *matchGroups;
@end

@implementation XJFriendGroupSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
    //self.searchBar.backgroundImage = [UIImage imageNamed:@"empty.png"];

    _matchGroups = [[NSMutableArray alloc]init];
    
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
    _friendGroupCell3Registered = 0;
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

#pragma search bar delegate
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"搜索%@", searchBar.text);
    [searchBar resignFirstResponder];
    [self searchFriendGroup:searchBar.text];

}
#pragma mark - UITableView DataSource Delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_matchGroups count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_friendGroupCell3Registered) {
        UINib *nib = [UINib nibWithNibName:@"XJFriendGroupCell3" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"friendGroupCell3Identifier"];
        _friendGroupCell3Registered = true;
    }
    XJFriendGroupCell3 *cell = [tableView dequeueReusableCellWithIdentifier:@"friendGroupCell3Identifier"];
    if(cell == nil)
        cell = [[XJFriendGroupCell3 alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"friendGroupCell3Identifier"];
    XJRunGroup *group = [_matchGroups objectAtIndex:indexPath.row];
    cell.name.text = group.groupName;
    cell.capacity.text = [NSString stringWithFormat:@"人数：%ld", (long)group.memberCount];
    cell.signature.text = [NSString stringWithFormat:@"签名：%@", group.signature];
    
    [cell.joinButton addTarget:self action:@selector(joinButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    //排除已经加入的跑团，拥有的跑团，申请过的跑团
    for (XJRunGroup *existGroup in _myAccount.runGroups) {
        if (existGroup.groupId == group.groupId) {
            [cell.joinButton setEnabled:NO];
            cell.joinButton.backgroundColor = [UIColor grayColor];
        }
    }
    return cell;
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)joinButtonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    XJFriendGroupCell3 *clickedCell = (XJFriendGroupCell3 *)[[button superview] superview];
    NSLog(@"%@ clicked", [clickedCell class]);
    NSIndexPath *indexPath = [self.tableView indexPathForCell:clickedCell];
    NSInteger groupId = [[_matchGroups objectAtIndex:indexPath.row] groupId];

    [self joinFriendGroup:[NSString stringWithFormat:@"%ld", (long)groupId] userId:[NSString stringWithFormat:@"%ld", (unsigned long)_myAccount.userID]];
}
-(void)joinFriendGroup:(NSString *)groupId userId:(NSString *)userId
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_USER_APPLY_RUN_GROUP];
    NSURL *url = [NSURL URLWithString: [urlPost stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    NSString *body = [NSString stringWithFormat:@"groupid=%@&userid=%@", groupId, userId];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"稍等" message:@"和服务器交互中" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];

    [alert show];
    void (^onDone)(NSData *data) = ^(NSData *data) {
        //__block XJFriendGroupSearchViewController *blockSelf = self;
        [alert dismissWithClickedButtonIndex:0 animated:NO];
        if(data == nil)
        {
            UIAlertView *alert1 = [[UIAlertView alloc]initWithTitle:@"服务器无响应" message:@"请稍候重试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert1 show];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        
        if (dict != nil) {
            if ([[dict valueForKey:@"id"]integerValue] != 0) {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"申请成功" message:@"等待团长审批" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
            }
            else
            {
                 UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"申请失败" message:@"服务器拒绝了您的申请" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
            }
            return;
        }
        else
        {
            UIAlertView *alert1 = [[UIAlertView alloc]initWithTitle:@"服务器无响应" message:@"请稍候重试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert1 show];
            return;
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

-(void)searchFriendGroup:(NSString *)groupName
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_SEARCH_RUN_GROUP];
    [urlPost appendFormat:@"%@", groupName];
    NSURL *url = [NSURL URLWithString: [urlPost stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"加载跑团。。" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [alert show];
    void (^onDone)(NSData *data) = ^(NSData *data) {
        __block XJFriendGroupSearchViewController *blockSelf = self;
        [_matchGroups removeAllObjects];
        [blockSelf.tableView reloadData];
        if(data == nil)
        {
            [alert dismissWithClickedButtonIndex:0 animated:NO];
            UIAlertView *alert1 = [[UIAlertView alloc]initWithTitle:@"无法搜索该跑团" message:@"无法连接服务器" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert1 show];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if (dict != nil) {
            [alert dismissWithClickedButtonIndex:0 animated:NO];
            [blockSelf proccessResponse:dict];
            
            return;
        }
        else
        {
            [alert dismissWithClickedButtonIndex:0 animated:NO];

            UIAlertView *alert1 = [[UIAlertView alloc]initWithTitle:@"未搜索到该跑团" message:@"无法连接服务器" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert1 show];
            return;
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

-(void)proccessResponse:(NSDictionary *)dict
{
    NSInteger groupCount = [[dict valueForKey:@"id"]integerValue];
    NSDictionary *runGroup = [dict valueForKey:@"rungroup"];
    [_matchGroups removeAllObjects];
    if (groupCount != 0 && runGroup != nil) {
        for (NSDictionary *groupItem in runGroup) {
            XJRunGroup *group = [[XJRunGroup alloc]init];
            group.groupName = [groupItem valueForKey:@"name"];
            group.groupId = [[groupItem valueForKey:@"id"]integerValue];
            group.memberCount = [[groupItem valueForKey:@"membercount"]integerValue];
            group.signature = [groupItem valueForKey:@"description"];
            [_matchGroups addObject:group];
        }
    }
    [self.tableView reloadData];
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
