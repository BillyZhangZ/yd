//
//  XJFriendManageViewController.m
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJFriendManageViewController.h"
#import "XJFriendGroupCell2.h"

#import "XJFriends.h"
#import "AppDelegate.h"
#import "config.h"
#import "XJAccount.h"
#import "WXApi.h"
#import "WXApiObject.h"

@interface XJFriendManageViewController ()<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL friendGroupCell2Registered;
    XJRunGroup *_group;
    NSMutableArray *_applyUserList;
    NSMutableArray *_MemberList;
}
@property (nonatomic,weak) XJAccount *myAccount;

@end

@implementation XJFriendManageViewController
-(instancetype)initWithGroup:(XJRunGroup *)group
{
    self = [super init];
    if (self) {
        _group = group;
        _applyUserList = [[NSMutableArray alloc]init];
        _MemberList = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [[UIImage alloc]init];

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
    
    [self getFriendGroupApplyMembers];
    [self getGroupMembers];
}
-(void)dealloc
{
    NSLog(@"group detail dealoc");
}
- (IBAction)inviteWechatFriend:(id)sender {
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    WXWebpageObject *webPageObject = [[WXWebpageObject alloc]init];
    
   // webPageObject.webpageUrl
     //= [[NSString stringWithFormat:@"Pao123://joinRunGroup:%ldname:%@count:%ldsignature:%@", (long)_group.groupId, _group.groupName, _group.memberCount, _group.signature] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    webPageObject.webpageUrl = [NSString stringWithFormat:@"Pao123://joinRunGroup:%ld", (long)_group.groupId];
    //webPageObject.webpageUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //NSLog(@"isOK:%d",[[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:webPageObject.webpageUrl]] );
    
    WXMediaMessage *mediaMessage = [[WXMediaMessage alloc]init];
    mediaMessage.mediaObject = webPageObject;
    mediaMessage.title = [NSString stringWithFormat:@"加入我的跑团《%@》",_group.groupName];
    mediaMessage.description = @"加入我的跑团，我们就可以一起跑啦！";
    mediaMessage.thumbData = UIImagePNGRepresentation([UIImage imageNamed:@"fire.png"]);
    req.text = @"";
    req.bText = NO;
    req.message = mediaMessage;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req];

}
- (IBAction)inviteWechatTimeLine:(id)sender {
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    WXWebpageObject *webPageObject = [[WXWebpageObject alloc]init];
    webPageObject.webpageUrl = @"Pao123://跑团号码";
    WXMediaMessage *mediaMessage = [[WXMediaMessage alloc]init];
    mediaMessage.mediaObject = webPageObject;
    mediaMessage.title = [NSString stringWithFormat:@"加入我的跑团《%@》",_group.groupName];
    mediaMessage.description = @"跑团描述暂时为空，头像也要从跑团获得哦！";
    mediaMessage.thumbData = UIImagePNGRepresentation([UIImage imageNamed:@"fire.png"]);
    req.text = @"";
    req.bText = NO;
    req.message = mediaMessage;
    req.scene = WXSceneTimeline;
    
    [WXApi sendReq:req];

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
    if (section == 0) {
        return [_applyUserList count];

    }
    else
    {
        return [_MemberList count];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
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
    if (indexPath.section == 0) {
        XJFriends *applyUser = [_applyUserList objectAtIndex:indexPath.row];
        cell.name.text = applyUser.nickName;
        [cell.accept addTarget:self action:@selector(acceptButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [cell.decline addTarget:self action:@selector(declineButtonClicked:) forControlEvents:UIControlEventTouchUpInside];    return cell;
    }
    else
    {
        //member list
        XJFriends *member = [_MemberList objectAtIndex:indexPath.row];
        cell.name.text = member.nickName;
        cell.accept.hidden = cell.decline.hidden = YES;
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)path
{
    return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect viewFrame = CGRectMake(0, 0, tableView.bounds.size.width, 30);
    UIView *view = [[UIView alloc]initWithFrame:viewFrame];
    view.backgroundColor= [UIColor colorWithRed:31/255.0 green:31/255.0 blue:34/255.0 alpha:0.4];
    CGRect LabelFrame = CGRectMake(10, 0, 150, 30);
    UILabel *label = [[UILabel alloc] initWithFrame:LabelFrame];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = [UIColor whiteColor];
    [view addSubview:label];

    if (section == 0) {
        label.text = @"批准申请";
    }
    else
    {
        label.text = @"成员列表";
    }
    return view;
}

-(void)acceptButtonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    XJFriendGroupCell2 *clickedCell = (XJFriendGroupCell2 *)[[button superview] superview];
    NSLog(@"%@ clicked", [clickedCell class]);
    NSIndexPath *indexPath = [self.tableView indexPathForCell:clickedCell];
    NSInteger userId = [(XJFriends *)[_applyUserList objectAtIndex:indexPath.row] myId];
    
    NSLog(@"accept button clicked");
    [self approveApply:userId approve:YES];
}

-(void)declineButtonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    XJFriendGroupCell2 *clickedCell = (XJFriendGroupCell2 *)[[button superview] superview];
    NSLog(@"%@ clicked", [clickedCell class]);
    NSIndexPath *indexPath = [self.tableView indexPathForCell:clickedCell];
    NSInteger userId = [(XJFriends *)[_applyUserList objectAtIndex:indexPath.row] myId];
    
    NSLog(@"decline button clicked");
    [self approveApply:userId approve:NO];
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)getFriendGroupApplyMembers
{
    NSLog(@"start get run group");
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_GET_RUN_GROUP_APPLY_INFO];
    [urlPost appendFormat:@"%lu",(unsigned long)_group.groupId];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        __block XJFriendManageViewController *blockSelf = self;
        NSLog(@"end get run group");
        if(data == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法获取跑团请求" message:@"服务器无响应" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            [blockSelf proccessApplyMemberResponse:dict];
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

-(void)proccessApplyMemberResponse:(NSDictionary *)dict
{
    NSDictionary *applyUserList = [dict valueForKey:@"apply"];
   
    for (NSDictionary *user in applyUserList) {
        XJFriends *friend = [[XJFriends alloc]init];
        friend.myId = [[user objectForKey:@"userid"] integerValue];
        friend.name = [user objectForKey:@"username"];
        friend.nickName = @"我没昵称";
        if ((NSNull *)[user objectForKey:@"nickname"] != [NSNull null]) {
            friend.nickName = [user objectForKey:@"nickname"];
        }
        [_applyUserList addObject:friend];
    }
    [self.tableView reloadData];
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
        __block XJFriendManageViewController *blockSelf = self;
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

-(void)approveApply:(NSInteger)userId approve:(BOOL)ok
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_APPROVE_JOIN_RUN_GROUP];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    NSString *body = [NSString stringWithFormat:@"groupid=%ld&userid=%ld&result=%d", (long)_group.groupId, (long)userId, ok];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"处理请求中。。" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [alert show];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        [alert dismissWithClickedButtonIndex:0 animated:NO];
        __block XJFriendManageViewController *blockSelf = self;
        if(data == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法处理该请求" message:@"服务器无响应" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"处理成功" message:@"" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            for (XJFriends *user  in _applyUserList) {
                if (user.myId == userId) {
                    [_applyUserList removeObject:user];
                    break;
                }
            }
            
            [blockSelf.tableView reloadData];
            [alert show];
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
