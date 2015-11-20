//
//  XJAddressBookFriendsVC.m
//  Pao123
//
//  Created by 张志阳 on 15/6/29.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJAddressBookFriendsVC.h"
#import "AppDelegate.h"
#import "config.h"
#import "XJFriendsAddressBookCell.h"
#import "XJFriends.h"

#import <MessageUI/MFMessageComposeViewController.h>

@interface Contact : NSObject
{
}
@property (nonatomic,readwrite) NSInteger userId;
@property (nonatomic, strong) NSString *nickName;//nickname
@property (nonatomic, strong) NSString *name;//name
@property (nonatomic,readwrite) NSInteger status;
@end
@implementation Contact

@end
@interface XJAddressBookFriendsVC ()<UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate,UIGestureRecognizerDelegate>
{
    BOOL cellRegistered;
    BOOL loadContactOk;
}
@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, weak) XJAccount *myAccount;
@end

@implementation XJAddressBookFriendsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    _myAccount = app.accountManager.currentAccount;
    _contacts = [[NSMutableArray alloc]init];
    loadContactOk = 0;
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];

    UIScreenEdgePanGestureRecognizer * screenEdgePan
    = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    screenEdgePan.delegate = self;
    screenEdgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:screenEdgePan];
    
    //加载通讯录
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            //查询所有
            [self filterContentForSearchText:@""];
        }
    });
    CFRelease(addressBook);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)filterContentForSearchText:(NSString*)searchText

{
    NSArray *listContacts = [[NSArray alloc]init];
    //如果没有授权则退出
    if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        return ;
    }
    
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if([searchText length]==0)
    {
        //查询所有
        listContacts = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    } else {
        //条件查询
        CFStringRef cfSearchText = (CFStringRef)CFBridgingRetain(searchText);
        listContacts = CFBridgingRelease(ABAddressBookCopyPeopleWithName(addressBook, cfSearchText));
        CFRelease(cfSearchText);
    }
    for (id record in listContacts) {
        ABRecordRef thisPerson = CFBridgingRetain(record);
        Contact *contact = [[Contact alloc]init];
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(thisPerson, kABPersonFirstNameProperty));
        firstName = firstName != nil?firstName:@"";
        NSString *lastName =  CFBridgingRelease(ABRecordCopyValue(thisPerson, kABPersonLastNameProperty));
        lastName = lastName != nil?lastName:@"";
        
        ABMultiValueRef multiValue = ABRecordCopyValue(thisPerson, kABPersonPhoneProperty);
        NSMutableString *rawPhoneNumber = (NSMutableString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValue, 0));
        NSString * phoneNumber1 = [rawPhoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSString * phoneNumber2 = [phoneNumber1 stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        NSString * phoneNumber3 = [phoneNumber2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        contact.nickName = [NSString stringWithFormat:@"%@ %@",lastName, firstName];
        contact.name = phoneNumber3;
        NSLog(@"%@", contact.name);
        if(![self isMobileNumber:contact.name]) continue;

        [_contacts addObject:contact];
        CFRelease(thisPerson);
    }
    
    //enum _listNumbers
    //for (NSString *number in _listNumbers) {
    //}
    //search whether this gay is my friend
    NSMutableArray *numberArray = [[NSMutableArray alloc]init];
    for (Contact *contact  in _contacts) {
        [numberArray addObject:contact.name];
    }
    NSString *numbers = [numberArray componentsJoinedByString:@","];
    
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_SEARCH_USERS_BY_NAME_LIST];
    //[urlPost appendString:numbers];namelist=
    
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    NSString *string = [[NSString alloc] initWithFormat:@"namelist=%@",numbers];
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            NSLog(@"get friend relationship nil");
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSDictionary *friends = [dict valueForKey:@"friends"];
        NSLog(@"%@", friends);
 
        int i = 0;
        for (NSString *friend in friends) {
            if ([[friend valueForKey:@"id"] integerValue] == 0) {
                //可以邀请
                Contact *con = (Contact *)[_contacts objectAtIndex:i];
                con.status = 0;
                con.userId = 0;
            }
            else
            {
                //可以添加好友
                Contact *con = (Contact *)[_contacts objectAtIndex:i];
                con.status = 1;
                con.userId = [[friend valueForKey:@"id"]integerValue];
                for ( XJFriends *friend in _myAccount.friends) {
                    if ([friend.name isEqual: con.name]) {
                        con.status = 2;
                        break;
                    }
                }
                if (con.status == 1) {
                    [_contacts removeObject:con];
                    [_contacts insertObject:con atIndex:0];
                }
                
            }
            i++;
        }
        //check the status
        loadContactOk = true;
        [self.tableView reloadData];
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

    //[self.tableView reloadData];
    CFRelease(addressBook);
}

- (BOOL)isMobileNumber:(NSString *)mobileNum{
    NSString * MOBILE = MOBILE_PHONE_NUMBER;
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    if ([regextestmobile evaluateWithObject:mobileNum] == YES)
    {
        return YES;
    }else{
        return NO;
    }
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    cellRegistered = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)dealloc
{
    NSLog(@"add friend from address book dealloc");
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
    if (loadContactOk == true) {
        return [_contacts count];
    }
    else
    {
        return 0;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - UITableView View Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!cellRegistered) {
        UINib *nib = [UINib nibWithNibName:@"XJFriendsAddressBookCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"addressBookCell"];
        cellRegistered = true;
    }
    
     XJFriendsAddressBookCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addressBookCell"];
    if(cell == nil)
        cell = [[XJFriendsAddressBookCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"addressBookCell"];
    
    cell.name.text = [(Contact *)[_contacts objectAtIndex:indexPath.row] nickName];
    
    NSInteger status =  [(Contact *)[_contacts objectAtIndex:indexPath.row] status];
    
    UIButton *button = (UIButton *)cell.status;
    //place to defaut, since has been reused
    [button setEnabled:YES];
    if (status == 0) {
        [button addTarget:self action:@selector(inviteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [button setTitle: @"邀请" forState:UIControlStateNormal];
    }
    else if(status == 1)
    {
        [button addTarget:self action:@selector(addButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle: @"添加" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:0xf0/255.0 green:0x65/255.0 blue:0x22/255.0 alpha:1.0] forState:UIControlStateNormal];
    }
    else if(status == 2)
    {
        [button setEnabled:false];
        [button setTitle: @"已添加" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] forState:UIControlStateNormal];
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}
#pragma mark - back button clicked
- (IBAction)backButtonClicked:(id)sender {
    //release related instanse refer
    
    //dissmiss self
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - invite button clicked
-(void)inviteButtonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    XJFriendsAddressBookCell *currentCell = (XJFriendsAddressBookCell *)[[button superview] superview];
    NSLog(@"%@",[[[button superview] superview]class]);
    NSString *string = nil;
    //wait for optimizing
    for (Contact *contact in _contacts) {
        if ([currentCell.name.text isEqual:contact.nickName]) {
            string = contact.name;
        }
    }
    
    if (string ==nil) {
        NSLog(@"No related number");
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法邀请" message:@"该用户号码格式不正确" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else
    {
        //NSString *smsUrl = [NSString stringWithFormat: @"sms://%@",string];
       // [[UIApplication sharedApplication] openURL: [NSURL URLWithString: smsUrl] ];
        NSArray *recipientList = [[NSArray alloc]initWithObjects:string, nil];
        [self sendSMS:@"我正在使用123go跑步软件，实时围观功能真的很炫酷，来试试吧！www.123yd.cn" recipientList:recipientList];
    }
}

-(void)addButtonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    XJFriendsAddressBookCell *currentCell = (XJFriendsAddressBookCell *)[[button superview] superview];
    NSLog(@"%@",[[[button superview] superview]class]);
    NSInteger friendId = 0;
    
    //wait for optimizing
    for (Contact *contact in _contacts) {
        if ([currentCell.name.text isEqual:contact.nickName]) {
            friendId = contact.userId;
        }
    }
    
    if (friendId == 0) {
        NSLog(@"No related number");
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无法添加" message:@"该用户号码格式不正确" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else
    {
        [currentCell.status setEnabled:NO];
        [_myAccount addFriend:friendId complete:^(bool ok){
            UIAlertView *alert;
            if (ok) {
                NSLog(@"添加好友成功");
                alert = [[UIAlertView alloc]initWithTitle:@"成功" message:@"等待对方同意" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
                [alert show];
                [currentCell.status setTitle:@"等待" forState:UIControlStateNormal];
                [currentCell.status setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            }
            else
            {
                alert = [[UIAlertView alloc]initWithTitle:@"失败" message:@"无法连接服务器或已申请" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
                [alert show];
                [currentCell.status setEnabled:YES];
                NSLog(@"添加好友失败");
            }
            [self performSelector:@selector(dismissAlert:) withObject:alert afterDelay:1.0];
        }];
    }
}

-(void)dismissAlert:(UIAlertView *)alert
{
    [alert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)sendSMS:(NSString *)bodyOfMessage recipientList:(NSArray *)recipients
{
    
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    
    if([MFMessageComposeViewController canSendText])
        
    {
        
        controller.body = bodyOfMessage;
        
        controller.recipients = recipients;
        
        controller.messageComposeDelegate = self;
        
        [self presentViewController:controller animated:NO completion:nil];
        
    }   
    
}

// 处理发送完的响应结果
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:NO completion:nil];
    
    if (result == MessageComposeResultCancelled)
        NSLog(@"Message cancelled");
        else if (result == MessageComposeResultSent)
            NSLog(@"Message sent");
            else
                NSLog(@"Message failed");
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
