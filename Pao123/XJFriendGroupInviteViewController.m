//
//  XJFriendGroupInviteViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/5.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJFriendGroupInviteViewController.h"
#import "config.h"
#import "XJAccount.h"
#import "AppDelegate.h"
#import "XJFriendGroupCell3.h"
@interface XJFriendGroupInviteViewController ()<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>
{
    BOOL _friendGroupCell3Registered;
}
@property (nonatomic) XJRunGroup *group;
@property (nonatomic) NSInteger userId;
@property (weak) XJAccount *myAccount;
@end

@implementation XJFriendGroupInviteViewController

-(instancetype)initWithRunGroup:(XJRunGroup *)runGroup userId:(NSInteger)userId
{
    self = [super init];
    if (self) {
        _group = runGroup;
        _userId = userId;
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
    
    _friendGroupCell3Registered = false;
    AppDelegate *app  = [[UIApplication sharedApplication]delegate];
    _myAccount = app.accountManager.currentAccount;
    
    [_group getGroupInfo:^(bool ok){
        if (ok) {
            NSLog(@"获取跑团信息成功");
            [self.tableView reloadData];
            
        }
        else
        {
            NSLog(@"无法获取跑团信息");
        }
    }];
    
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

- (IBAction)backButtonClicked:(id)sender {
      [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - UITableView DataSource Delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_group signature] == nil) {
        return 0;
    }
    return 1;
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
        cell = [[XJFriendGroupCell3 alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"XJFriendGroupCell3"];
    cell.name.text =  _group.groupName;
    //cell.capacity.text = [NSString stringWithFormat:@"人数：%ld", (long)_group.memberCount];
    cell.capacity.text = @"";
    cell.signature.text = [NSString stringWithFormat:@"签名：%@", _group.signature];
    if (_myAccount.runGroups != nil && [_myAccount.runGroups count] != 0) {
        for (XJRunGroup *group in _myAccount.runGroups) {
            if (group.groupId == _group.groupId) {
                [cell.joinButton setEnabled:NO];
                cell.joinButton.backgroundColor = [UIColor grayColor];
                return cell;
            }
        }
    }

    [cell.joinButton addTarget:self action:@selector(joinButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


-(void)joinButtonClicked:(id)sender
{
    [self joinFriendGroup:[NSString stringWithFormat:@"%ld", (long)_group.groupId] userId:[NSString stringWithFormat:@"%ld", (long)_userId]];
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
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        //__block XJFriendGroupSearchViewController *blockSelf = self;
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
