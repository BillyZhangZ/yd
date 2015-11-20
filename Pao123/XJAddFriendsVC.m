//
//  XJAddFriendsVC.m
//  Pao123
//
//  Created by 张志阳 on 15/6/29.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJAddFriendsVC.h"
#import "AppDelegate.h"
#import "config.h"
#import "WXApi.h"
#import "WXApiObject.h"
#import "XJAddressBookFriendsVC.h"
#import "XJFriendSearchResultVC.h"
#define ADD_FRIEND_FROM_PHONE_ADDRESS 0
#define ADD_FRIEND_FROM_WECHAT 1
@interface XJAddFriendsVC ()<UITableViewDataSource, UITableViewDelegate,UIGestureRecognizerDelegate>

@end

@implementation XJAddFriendsVC

- (void)viewDidLoad {
    DEBUG_ENTER;
    [super viewDidLoad];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];

    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];

    DEBUG_LEAVE;
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    DEBUG_ENTER;
    [super didReceiveMemoryWarning];
    DEBUG_LEAVE;
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    NSLog(@"add friend dealloc");
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


#pragma mark - UISearchBar delegate
-(BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return YES;
}

-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"%@", searchBar.text);
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_SEARCH_USER_BY_NAME];
    [urlPost appendFormat:@"%@", [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ];
    
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            NSLog(@"search user failed");
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSAssert(dict != nil, @"search user returned dict is nil ");
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            NSArray *userArray = [dict valueForKey:@"friends"];
             if ([userArray count] == 0) {
                //用户不存在
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无搜索结果" message:@"用户名不存在" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
                return;
            }
            XJFriendSearchResultVC *vc = [[XJFriendSearchResultVC alloc]init:userArray];
            
            [self presentViewController:vc animated:NO completion:nil];
            
        }
        else
        {
            //用户不存在
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无搜索结果" message:@"用户名不存在" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
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

#pragma mark - UITableView DataSource Delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kindOfFriendTableCell"];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"kindOfFriendTableCell"];
    switch (indexPath.row) {
        case ADD_FRIEND_FROM_PHONE_ADDRESS:
           // cell.imageView.image = [UIImage imageNamed:@"phoneAddress.png"];
            cell.textLabel.text = @"手机通讯录好友";
            break;
        case ADD_FRIEND_FROM_WECHAT:
            //cell.imageView.image = [UIImage imageNamed:@"wechat.png"];
            cell.textLabel.text = @"微信好友";
            break;
        default:
            break;
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];

    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XJAddressBookFriendsVC *vc = [[XJAddressBookFriendsVC alloc]init];
    switch (indexPath.row) {
        case ADD_FRIEND_FROM_PHONE_ADDRESS:
            [self presentViewController:vc animated:YES completion:nil];
            break;
        case ADD_FRIEND_FROM_WECHAT:
            [self invitWechatFriend];
            break;
        default:
            break;
    }
    
    [self performSelector:@selector(dummy) withObject:nil];
}

-(void)dummy
{
    
}

- (void)invitWechatFriend
{
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    WXWebpageObject *webPageObject = [[WXWebpageObject alloc]init];
    webPageObject.webpageUrl = @"www.123yd.cn/install";
    WXMediaMessage *mediaMessage = [[WXMediaMessage alloc]init];
    mediaMessage.mediaObject = webPageObject;
    mediaMessage.title = @"一起加入123Go!吧";
    mediaMessage.description = @"123Go!是一款专业的跑步软件, 让你跑步更放心。";
    
    mediaMessage.thumbData = UIImagePNGRepresentation([UIImage imageNamed:@"fire.png"]);
    req.text = @"";
    req.bText = NO;
    req.message = mediaMessage;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req];
}

- (void) sendImageInviteToWechatFriend
{
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    WXWebpageObject *webPageObject = [[WXWebpageObject alloc]init];
    
    webPageObject.webpageUrl = [NSString stringWithFormat:@"Pao123://joinRunGroup"];
    
    WXMediaMessage *mediaMessage = [[WXMediaMessage alloc]init];
    mediaMessage.mediaObject = webPageObject;
    mediaMessage.title = [NSString stringWithFormat:@"一起加入123Go!吧"];
    mediaMessage.description = @"123Go!是一款专业的跑步软件, 让你跑步更放心。";
    mediaMessage.thumbData = UIImagePNGRepresentation([UIImage imageNamed:@"fire.png"]);
    req.text = @"";
    req.bText = NO;
    req.message = mediaMessage;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req];
}

#pragma mark - back button clicked

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
@end
