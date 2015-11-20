//
//  XJFriendGroupViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/3.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//
#import "config.h"
#import "AppDelegate.h"
#import "XJFriendGroupViewController.h"
#import "XJFriendManageViewController.h"
#import "XJFriendGroupAddViewController.h"
#import "XJFriendGroupMemberListViewController.h"
#import "XJFriendGroupCell1.h"
#import "XJRunGroup.h"
@interface XJFriendGroupViewController ()<UITableViewDataSource, UITableViewDelegate,UIGestureRecognizerDelegate, PullTableViewDelegate>
{
    BOOL _friendGroupCell1Registered;
}
@property (nonatomic, weak) XJAccount *myAccount;
@property (nonatomic) NSMutableArray *joinGroup;
@property (nonatomic) NSMutableArray *ownGroup;
@property (nonatomic) NSMutableArray *applyGroup;

@property NSInteger joinGroupCount;
@property NSInteger ownGroupCount;
@property NSInteger applyGroupCount;

@end

@implementation XJFriendGroupViewController
-(instancetype)init
{
    self = [super init];
    if (self) {
        _joinGroup = [[NSMutableArray alloc]init];
        _ownGroup = [[NSMutableArray alloc]init];
        _applyGroup = [[NSMutableArray alloc]init];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [[UIImage alloc]init];
    self.tableView.pullArrowImage = [UIImage imageNamed:@"blackArrow"];
    self.tableView.pullBackgroundColor = [UIColor yellowColor];
    self.tableView.pullTextColor = [UIColor blackColor];
    
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
    _friendGroupCell1Registered = 0;
    _ownGroupCount = 0;
    _joinGroupCount = 0;
    _applyGroupCount = 0;
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    _myAccount = app.accountManager.currentAccount;
    [self runGroupClassify];
    [self.tableView reloadData];
}


-(void)dealloc
{
    NSLog(@"friend grounp dealloc");
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
    switch (section) {
        case 0:
            return [_ownGroup count];
            break;
        case 1:
            return [_joinGroup count];
            break;
        case 2:
            return [_applyGroup count];
            break;
        default:
            break;
    }
    return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!_friendGroupCell1Registered) {
        UINib *nib = [UINib nibWithNibName:@"XJFriendGroupCell1" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"friendGroupCell1Identifier"];
        _friendGroupCell1Registered = true;
    }
    XJFriendGroupCell1 *cell = [tableView dequeueReusableCellWithIdentifier:@"friendGroupCell1Identifier"];
    if(cell == nil)
        cell = [[XJFriendGroupCell1 alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"XJFriendGroupCell1"];
    XJRunGroup *group;
    switch (indexPath.section) {
        case 0:
            group = [_ownGroup objectAtIndex:indexPath.row];
            break;
        case 1:
            group = [_joinGroup objectAtIndex:indexPath.row];
            break;
        case 2:
            group = [_applyGroup objectAtIndex:indexPath.row];
            break;
        default:
            break;
    }

    //cell.portrait.image = [UIImage imageNamed:@"account.png"];
    cell.name.text =  group.groupName;
    cell.capacity.text = [NSString stringWithFormat:@"人数：%ld", (long)group.memberCount];
    cell.sign.text = [NSString stringWithFormat:@"人数：%@", group.signature];
    //cell.status.text = [NSString stringWithFormat:@"%ld个人在跑步中", (long)group.activeMemberCount];
    cell.status.text = @"";
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XJRunGroup *group = [_myAccount.runGroups objectAtIndex:indexPath.row];
    //我是团长，可以管理
    if (indexPath.section == 0) {
        NSLog(@"present group detail");
        XJFriendManageViewController *vc = [[XJFriendManageViewController alloc]initWithGroup:group];
        [self presentViewController:vc animated:NO completion:nil];
    }
    else if (indexPath.section == 1)
    {
       // XJFriendGroupMemberListViewController *vc = [[XJFriendGroupMemberListViewController alloc]initWithGroup:group];
        //[self presentViewController:vc animated:NO completion:nil];
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect viewFrame = CGRectMake(0, 0, tableView.bounds.size.width, 30);
    UIView *view = [[UIView alloc]initWithFrame:viewFrame];
    view.backgroundColor= [UIColor colorWithRed:31/255.0 green:31/255.0 blue:34/255.0 alpha:0.4];
    
    CGRect leftLabelFrame = CGRectMake(10, 0, 150, 30);
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:leftLabelFrame];
    leftLabel.textAlignment = NSTextAlignmentLeft;
    leftLabel.backgroundColor = [UIColor clearColor];
    leftLabel.textColor = [UIColor whiteColor];
    switch (section) {
        case 0:
            leftLabel.text = @"我是团长";
            break;
        case 1:
            leftLabel.text = @"我加入的团";
            break;
        case 2:
            leftLabel.text = @"正在申请中";
            break;
        default:
            break;
    }
    [view addSubview:leftLabel];
    return view;
}
- (IBAction)menuButtonClicked:(id)sender {
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app showMenu];
}

- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    NSLog(@"group: refresh");
    [self getFriendGroupFromServer];
}

- (IBAction)addGroupButtonClicked:(id)sender {
    XJFriendGroupAddViewController *vc = [[XJFriendGroupAddViewController alloc]init];
    [self presentViewController:vc animated:NO completion:nil];
}

-(void)getFriendGroupFromServer
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_GET_USER_RUN_GROUP_INFO];
    [urlPost appendFormat:@"%lu",(unsigned long)_myAccount.userID];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        __block XJFriendGroupViewController *blockSelf = self;
        blockSelf.tableView.pullTableIsRefreshing = NO;
        if(data == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法获取跑团信息" message:@"服务器无响应" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
#pragma fix me here server is wrong
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            [blockSelf proccessResponse:dict];
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

-(void)proccessResponse:(NSDictionary *)dict
{
    NSDictionary *joinedGroup = [dict valueForKey:@"joingroup"];
    NSDictionary *ownedGroup = [dict valueForKey:@"owngroup"];
    NSDictionary *appliedGroup = [dict valueForKey:@"applygroup"];
    NSMutableArray *groups = _myAccount.runGroups;
    [_myAccount.runGroups removeAllObjects];
    [_applyGroup removeAllObjects];
    [_joinGroup removeAllObjects];
    [_ownGroup removeAllObjects];

    
    for (NSDictionary *groupItem in ownedGroup) {
        XJRunGroup *group = [[XJRunGroup alloc]init];
        group.groupId = [[groupItem valueForKey:@"id"] integerValue];
        group.groupName = [groupItem valueForKey:@"name"];
        group.signature = [groupItem valueForKey:@"description"];
        group.memberCount = [[groupItem valueForKey:@"membercount"] integerValue];
        group.activeMemberCount = [[groupItem valueForKey:@"memberrunningcount"] integerValue];
        group.relationship = RELATIONSHIP_OWN;
        group.applyMemberCount = [[groupItem valueForKey:@"memberapplycount"] integerValue];
        [_ownGroup addObject:group];
        BOOL exist = false;
        for (XJRunGroup *existGroup in groups) {
            if (existGroup.groupId == [[groupItem valueForKey:@"id"] integerValue]) {
                exist = true;
            }
        }
        if (!exist) {
            [groups addObject:group];
        }

    }

    for (NSDictionary *groupItem in joinedGroup) {
        XJRunGroup *group = [[XJRunGroup alloc]init];
        group.groupId = [[groupItem valueForKey:@"id"] integerValue];
        group.groupName = [groupItem valueForKey:@"name"];
        group.signature = [groupItem valueForKey:@"description"];
        group.memberCount = [[groupItem valueForKey:@"membercount"] integerValue];
        group.activeMemberCount = [[groupItem valueForKey:@"memberrunningcount"] integerValue];
        group.relationship = RELATIONSHIP_JOIN;
        group.applyMemberCount = [[groupItem valueForKey:@"memberapplycount"] integerValue];
        [groups addObject:group];
        [_joinGroup addObject:group];
    }

    for (NSDictionary *groupItem in appliedGroup) {
        XJRunGroup *group = [[XJRunGroup alloc]init];
        group.groupId = [[groupItem valueForKey:@"id"] integerValue];
        group.groupName = [groupItem valueForKey:@"name"];
        group.signature = [groupItem valueForKey:@"description"];
        group.memberCount = [[groupItem valueForKey:@"membercount"] integerValue];
        group.relationship = RELATIONSHIP_APPLY;
        group.activeMemberCount = [[groupItem valueForKey:@"memberrunningcount"] integerValue];
        group.applyMemberCount = [[groupItem valueForKey:@"memberapplycount"] integerValue];
        [_applyGroup addObject:group];
        BOOL exist = false;
        for (XJRunGroup *existGroup in groups) {
            if (existGroup.groupId == [[groupItem valueForKey:@"id"] integerValue]) {
                exist = true;
            }
        }
        if (!exist) {
            [groups addObject:group];
        }

    }
    
    //生成view需要的自己的团 加入的团 申请的团
    _ownGroupCount = [ownedGroup count];
    _joinGroupCount = [joinedGroup count];
    _applyGroupCount = [appliedGroup count];
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    [app.accountManager storeAccountInfoToDisk];
    [self.tableView reloadData];
}

-(void)runGroupClassify
{
    NSMutableArray *groups = _myAccount.runGroups;
    [_applyGroup removeAllObjects];
    [_joinGroup removeAllObjects];
    [_ownGroup removeAllObjects];
    
    
    for (XJRunGroup *groupItem in groups) {
        if (groupItem.relationship != RELATIONSHIP_OWN) continue;
        [_ownGroup addObject:groupItem];

    }
    
    for (XJRunGroup *groupItem in groups) {
        if (groupItem.relationship != RELATIONSHIP_JOIN) {
            continue;
        }
       
        [_joinGroup addObject:groupItem];
    }
    
    for (XJRunGroup *groupItem in groups) {
        if (groupItem.relationship != RELATIONSHIP_APPLY) {
            continue;
        }
        [_applyGroup addObject:groupItem];
    }
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
