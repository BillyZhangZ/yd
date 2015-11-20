//
//  XJNewFriendsVC.m
//  Pao123
//
//  Created by 张志阳 on 15/6/30.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJNewFriendsVC.h"
#import "XJNewFriendsCell.h"
#import "XJFriends.h"
#import "AppDelegate.h"
#import "config.h"
@interface XJNewFriendsVC ()<UITableViewDataSource, UITableViewDelegate,UIGestureRecognizerDelegate>
{
    BOOL cellRegistered;
    NSMutableArray *_applyList;
}
@end

@implementation XJNewFriendsVC

-(instancetype)initWithApplyFriendList:(NSMutableArray *)applyFriendList
{
    self = [super init];
    if (self) {
        _applyList = applyFriendList;
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
    cellRegistered = false;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    cellRegistered = NO;
}

-(void)dealloc
{
    NSLog(@"new friend dealloc");
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
    //个数为姓氏首字母相同的所有好友
    return [_applyList count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!cellRegistered) {
        UINib *nib = [UINib nibWithNibName:@"XJNewFriendsCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"newFriendsCellIdentifier"];
        cellRegistered = true;
    }
    
    XJNewFriendsCell  *cell = [tableView dequeueReusableCellWithIdentifier:@"newFriendsCellIdentifier"];
    if(cell == nil)
        cell = [[XJNewFriendsCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"newFriendsCell"];
   
    cell.portriatImage.image = [UIImage imageNamed:@"account.png"];
    cell.nameLabel.text = [(XJFriends *)[_applyList objectAtIndex:indexPath.row] nickName];
    [cell.approveButton addTarget:self action:@selector(approveButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [cell.declineButton addTarget:self action:@selector(declineButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

-(void)approveButtonClicked:(UIButton *)sender
{
    XJNewFriendsCell *selectedCell = (XJNewFriendsCell *)[[sender superview]superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
    XJFriends *friend = [_applyList objectAtIndex:indexPath.row];
    [sender setEnabled:NO];
    [self approveFriend:friend approve:ACCEPT_FRIEND];
}

-(void)declineButtonClicked:(UIButton *)sender
{
    XJNewFriendsCell *selectedCell = (XJNewFriendsCell *)[[sender superview]superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
    XJFriends *friend = [_applyList objectAtIndex:indexPath.row];
    [sender setEnabled:NO];
    [self approveFriend:friend approve:REJECT_FRIEND];
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
}
- (IBAction)backButtonClicked:(id)sender {
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

-(void)approveFriend:(XJFriends *)friend  approve:(NSInteger)isAccept
{
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    NSInteger userId = app.accountManager.currentAccount.userID;
    NSInteger friendId = friend.myId;
    
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_APPROVE_FRIEND_APPLY];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    NSString *body = [NSString stringWithFormat:@"userid=%ld&friendid=%ld&result=%ld", (long)userId, (long)friendId, (long)isAccept];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法处理该请求" message:@"服务器无响应" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            if (isAccept == ACCEPT_FRIEND) {
                friend.pendingState = STATE_ALREADY_FRIEND;
                [app.accountManager.currentAccount.friends addObject:friend];
                [app.accountManager storeAccountInfoToDisk];
            }
            [_applyList removeObject:friend];
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"操作成功" message:@"" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            [self.tableView reloadData];
            return;
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法处理该请求" message:@"服务器拒绝了你" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
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

@end
