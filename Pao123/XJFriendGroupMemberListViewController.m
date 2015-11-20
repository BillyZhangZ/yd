//
//  XJFriendManageViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJFriendGroupMemberListViewController.h"
#import "XJFriendGroupCell2.h"
#import "XJFriendInfoVC.h"
#import "XJFriends.h"
#import "AppDelegate.h"
#import "config.h"
#import "XJAccount.h"


@interface XJFriendGroupMemberListViewController ()<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL friendGroupCell2Registered;
    XJRunGroup *_group;
    NSMutableArray *_MemberList;
}
@property (nonatomic,weak) XJAccount *myAccount;

@end

@implementation XJFriendGroupMemberListViewController
-(instancetype)initWithGroup:(XJRunGroup *)group
{
    self = [super init];
    if (self) {
        _group = group;
        _MemberList = [[NSMutableArray alloc]init];
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
    friendGroupCell2Registered = 0;
    
    [self getGroupMembers];
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
    
    return [_MemberList count];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!friendGroupCell2Registered) {
        UINib *nib = [UINib nibWithNibName:@"XJFriendGroupCell2" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"friendGroupCell2Identifier"];
        friendGroupCell2Registered = true;
    }
    XJFriendGroupCell2 *cell = [tableView dequeueReusableCellWithIdentifier:@"friendGroupCell2Identifier"];
    if(cell == nil)
        cell = [[XJFriendGroupCell2 alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"friendGroupCell2Identifier"];
   
    
    //member list
    XJFriends *member = [_MemberList objectAtIndex:indexPath.row];
    cell.name.text = member.nickName;
    cell.accept.hidden = YES;
    [cell.decline setTitle:@"观看" forState:UIControlStateNormal];
    [cell.decline addTarget:self action:@selector(watchFriendButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

-(void)watchFriendButtonClicked:(UIButton *)sender
{
    NSLog(@"watch %@", @"");
}
- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)path
{
    return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect viewFrame = CGRectMake(0, 0, tableView.bounds.size.width, 30);
    UIView *view = [[UIView alloc]initWithFrame:viewFrame];
    view.backgroundColor= [UIColor grayColor];
    CGRect LabelFrame = CGRectMake(tableView.bounds.size.width/2 - 75, 0, 150, 30);
    UILabel *label = [[UILabel alloc] initWithFrame:LabelFrame];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    [view addSubview:label];
    
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XJFriendInfoVC *vc = [[XJFriendInfoVC alloc]init];
    vc.myself = [_MemberList objectAtIndex:indexPath.row];
    [self presentViewController:vc animated:NO completion:nil];
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}
-(void)getGroupMembers
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_GET_RUN_GROUP_MEMBERS];
    [urlPost appendFormat:@"%lu",(unsigned long)_group.groupId];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        __block XJFriendGroupMemberListViewController *blockSelf = self;
        if(data == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法获取跑团成员" message:@"服务器无响应" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            [blockSelf proccessFetchMemberResponse:dict];
            return;
        }
        else
        {
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

-(void)proccessFetchMemberResponse:(NSDictionary *)dict
{
    NSDictionary *applyUserList = [dict valueForKey:@"member"];
    
    for (NSDictionary *user in applyUserList) {
        XJFriends *friend = [[XJFriends alloc]init];
        friend.myId = [[user objectForKey:@"id"] integerValue];
        friend.name = [user objectForKey:@"name"];
        friend.nickName = @"我没昵称";
        if ((NSNull *)[user objectForKey:@"nickname"] != [NSNull null]) {
            friend.nickName = [user objectForKey:@"nickname"];
        }
        [_MemberList addObject:friend];
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
