//
//  AppDelegate.m
//  Pao123
//
//  Created by Chen Zhenyong on 24/5/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "AppDelegate.h"
#import "XJMainVC.h"
#import <MAMapKit/MAMapKit.h>
#import <SMS_SDK/SMS_SDK.h>
#import "XJMenuView.h"
#import "WXApi.h"
#import "XJUserVC.h"
#import "XJLoginVC.h"
#import "XJHistoryViewController.h"
#import "XJSettingsVC.h"
#import "HeartRateDevice.h"
#import "XJFriendsVC.h"
#import "XJRunGroup.h"
#import "XJFriendGroupInviteViewController.h"
#import "UncaughtExceptionHandler.h"
#import "XJLogger.h"
#import "AVFoundation/AVAudioSession.h"
#import "XJSMSLoginViewController.h"
#import "XJRealplayListVC.h"
#import "XJWorkoutListVC.h"
#import "APService.h"
#import "XJUserHomeViewController.h"
#import "XJFriendGroupViewController.h"
#import "Reachability.h"
#import "RunningListVC.h"
@interface AppDelegate ()<WXApiDelegate>
{
    XJMenuView *_menuView;
    
    // VCs
    XJMainVC *_mainVC;
    XJUserHomeViewController *_userVC;
    XJSMSLoginViewController *_loginVC;
    XJHistoryViewController *_histVC;
    XJSettingsVC *_settingsVC;
    XJFriendsVC *_friendsVC;
    XJFriendGroupViewController *_friendGroup;
    RunningListVC *_realplayListVC;
//    XJWorkoutListVC *_workoutListVC;

    // heart-rate device
    HeartRateDevice *_heartRateDev;
    
    // debug support
    XJLogger *_logger;
    
    Reachability *_hostReach;
    Reachability *_wifiReach;
}

@end

@implementation AppDelegate
//暂时用于存储workout截图，后面应该存放在每个workout里面
@synthesize savedMapView = _savedMapView;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if 0
    for(NSString *familyName in [UIFont familyNames]){
        NSLog(@"Font FamilyName = %@",familyName); //*输出字体族科名字
        for(NSString *fontName in [UIFont fontNamesForFamilyName:familyName]){ NSLog(@"t%@",fontName); //*输出字体族科下字样名字
        }
    }
#endif
    // prevent landscape splash screen causes wrong size of viewcontroller on iPhone 6 Plus (must put it as earlier as possible)
    application.statusBarOrientation = UIInterfaceOrientationPortrait;

    InstallUncaughtExceptionHandler();
    _logger = [[XJLogger alloc] init];

    // Override point for customization after application launch.
    _accountManager = [[XJAccountManager alloc] init];

    [MAMapServices sharedServices].apiKey = @"ebdb3fe48530565d85bc349d87787eb5";
    //向微信注册pao123应用，同时已经在target info里面添加了URL types
    [WXApi registerApp:@"wx9d60ab46bfa2d903" withDescription:@"runhelper"];
    
    [SMS_SDK registerApp:@"8e3172640a7a"  withSecret:@"3857e35be71e6df2b22b1064b5beda03"];
    // create window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // determin layout scale
    [self calcUIScale];

    // create the menu panel
    CGRect rc = [[UIScreen mainScreen] bounds];
    _menuView = [[XJMenuView alloc] initWithFrame:rc];

    // create the default workout panel
    _mainVC = [[XJMainVC alloc] init];
    self.window.rootViewController = _mainVC;

    // create other VCs
    _histVC = [[XJHistoryViewController alloc] init];
    _userVC = [[XJUserHomeViewController alloc] init];
    _loginVC = [[XJSMSLoginViewController alloc]init]; //[[XJLoginVC alloc] init];
    _settingsVC = [[XJSettingsVC alloc] init];
    _friendsVC = [[XJFriendsVC alloc] init];
    _friendGroup = [[XJFriendGroupViewController alloc]init];
    _realplayListVC = [[RunningListVC alloc] init];
//    _workoutListVC = [[XJWorkoutListVC alloc] init];
    
    _networkStatus = 0;
    [self.window makeKeyAndVisible];

    _heartRateDev = [[HeartRateDevice alloc] init:self];
    
    NSLog(@"Load workout data");

    // let voice can be heard when app is at background, and use MIX to prevent pausing music player
    NSError *error = NULL;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback
                                 withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    // APNS related
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //categories
        [APService
         registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                             UIUserNotificationTypeSound |
                                             UIUserNotificationTypeAlert)
         categories:nil];
    } else {
        //categories nil
        [APService
         registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                             UIUserNotificationTypeSound |
                                             UIUserNotificationTypeAlert)
#else
         //categories nil
         categories:nil];
        [APService
         registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                             UIRemoteNotificationTypeSound |
                                             UIRemoteNotificationTypeAlert)
#endif
         // Required
         categories:nil];
    }
    [APService setupWithOption:launchOptions];

    //处理不同启动方式
    NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if(url)
    {
        //other app
        NSLog(@"启动url %@", url);
    }
    NSString *bundleId = [launchOptions objectForKey:UIApplicationLaunchOptionsSourceApplicationKey];
    if(bundleId)
    {
        NSLog(@"启动应用名称 %@", bundleId);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:bundleId message: [url absoluteString]  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    UILocalNotification * localNotify = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if(localNotify)
    {
        NSLog(@"本地通知打开应用");
    }
    NSDictionary * userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(userInfo)
    {
        NSLog(@"远程通知打开应用");
        if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
            
            UIApplication *app = [UIApplication sharedApplication];
            
            // 应用程序右上角数字
            app.applicationIconBadgeNumber = 0;
        }
        else
        {
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge categories:nil];
            
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            
            UIApplication *app = [UIApplication sharedApplication];
            // 应用程序右上角数字
            app.applicationIconBadgeNumber = 0;
        }
        XJHistoryViewController *vc = [[XJHistoryViewController alloc]init];
        [self.window.rootViewController presentViewController:vc animated:NO completion:nil];
    }
    
    //添加网络环境变化监听
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    
    _hostReach = [Reachability reachabilityWithHostName: @"www.123yd.cn"];
    [_hostReach startNotifier];
    
    _wifiReach=[Reachability reachabilityForLocalWiFi];
    [_wifiReach startNotifier];
    return YES;
}

- (void)reachabilityChanged: (NSNotification* )note {
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:
        {
            NSLog(@"Access Not Available");
            _networkStatus = 0;
            break;
        }
            
        case ReachableViaWWAN:
        {
            NSLog(@"Reachable WWAN");
            _networkStatus = 1;
            break;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"Reachable WiFi");
            _networkStatus = 2;
            break;
        }
    }
    
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

//外部应用调用123go时，如果123go在后台，那么会调用此程序获取传递的消息，调用顺序，WillEnterForeground－》application openURL－》DidBecomeActive
- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        
        UIApplication *app = [UIApplication sharedApplication];
        
        // 应用程序右上角数字
        app.applicationIconBadgeNumber = 0;
    }
    else
    {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
        UIApplication *app = [UIApplication sharedApplication];
        // 应用程序右上角数字
        app.applicationIconBadgeNumber = 0;
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation NS_AVAILABLE_IOS(4_2)

{
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:sourceApplication message: [url absoluteString]  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    //[alert show];
    [self proccessWechatCmd: [url absoluteString]];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Required
    [APService registerDeviceToken:deviceToken];
    _devicePushId = [APService registrationID];
   // NSLog(@"%@", [APService registrationID]);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

//远程通知调用该接口，会调用该接口
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler {
    // IOS 7 Support Required    ￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼￼
    NSLog(@"this is iOS7 or later Remote Notification");
    if (application.applicationState == UIApplicationStateActive) {
        // 转换成一个本地通知，显示到通知栏，你也可以直接显示出一个alertView，只是那样稍显aggressive：）
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification = [APService
                             setLocalNotification:([[NSDate date] dateByAddingTimeInterval:1])
                             alertBody:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
                             badge:-1
                             alertAction:@"观看"
                             identifierKey:@"1"
                             userInfo:userInfo
                             soundName:UILocalNotificationDefaultSoundName];
    }
    else
    {
        // Required
        [APService handleRemoteNotification:userInfo];
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

//收到本地通知后，调用该接口
- (void)application:(UIApplication *)application
didReceiveLocalNotification:(UILocalNotification *)notification {
    [APService showLocalNotificationAtFront:notification identifierKey:nil];
    //notification里携带了本地推送的消息
}

//注册本地通知设置后，会调用此接口
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:
(UIUserNotificationSettings *)notificationSettings {
    
}

// Called when your app has been activated by the user selecting an action from
// a local notification.
// A nil action identifier indicates the default action.
// You should call the completion handler as soon as you've finished handling
// the action.
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification
  completionHandler:(void (^)())completionHandler {
    NSLog(@"处理本地通知action");
    
}

// Called when your app has been activated by the user selecting an action from
// a remote notification.
// A nil action identifier indicates the default action.
// You should call the completion handler as soon as you've finished handling
// the action.
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)())completionHandler {
    NSLog(@"处理远程通知action");
}

-(void)proccessWechatCmd:(NSString *)cmd
{
    //Pao123://joinRunGroup:%ld
    NSArray *cmdContent = [cmd componentsSeparatedByString:@"//"];
    NSString *action = [cmdContent objectAtIndex:1];
    NSArray *actionObjects = [action componentsSeparatedByString:@":"];
    NSString *actionCmd = [actionObjects objectAtIndex:0];
    
    if ([actionCmd isEqualToString:@"joinRunGroup"]) {
        XJRunGroup *group = [[XJRunGroup alloc]init];
        NSString *groupId = [actionObjects objectAtIndex:1];
      //  NSString *groupName = [actionObjects objectAtIndex:2];
     //   NSString *groupCount = [actionObjects objectAtIndex:3];
      //  NSString *groupSignature = [actionObjects objectAtIndex:4];

        group.groupId = [groupId integerValue];
     //   group.groupName = groupName;
     //   group.memberCount = [groupCount integerValue];
     //   group.signature = groupSignature;
        XJFriendGroupInviteViewController *vc = [[XJFriendGroupInviteViewController alloc] initWithRunGroup:group userId:_accountManager.currentAccount.userID];
        [self.window.rootViewController presentViewController:vc animated:NO completion:nil];
    }
}

-(void)proccessPushCmd:(NSString *)cmd
{
    
}
- (void) showMenu
{
    // update menu content
    if (self.accountManager.currentAccount.nickName == nil) {
        _menuView.lblName.text = self.accountManager.currentAccount.user;
    }
    else
    _menuView.lblName.text = self.accountManager.currentAccount.nickName;

    CGRect rc = _menuView.frame;
    rc.origin.x = - lo_menu_width * rate_pixel_to_point;
    _menuView.frame = rc;
    [self.window addSubview:_menuView];

    // 动画执行开始
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationRepeatAutoreverses:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.window cache:YES];
    [UIView setAnimationDuration:0.7];
    // 设置要变化的frame 推入与推出修改对应的frame即可
    rc.origin.x = 0;
    _menuView.frame = rc;
    // 执行动画
    [UIView commitAnimations];
}

- (void) hideMenu
{
    CGRect rc = _menuView.frame;
    rc.origin.x = - lo_menu_width * rate_pixel_to_point;
    _menuView.frame = rc;
    [_menuView removeFromSuperview];
}

-(void)jumpToMainVC
{
    _window.rootViewController = _mainVC;
}
- (void) onMenuItemClicked:(NSString *)itemName
{
    if([itemName compare:@"User"] == NSOrderedSame)
    {
        if (_accountManager.currentAccount == _accountManager.guestAccount) {
            _window.rootViewController = _loginVC;
        }
        else
        {
            _window.rootViewController = _userVC;
        }

    }
    else if([itemName compare:@"开始跑"] == NSOrderedSame)
    {
        _window.rootViewController = _mainVC;
    }
    else if([itemName compare:@"跑步历史"] == NSOrderedSame)
    {
        _window.rootViewController = _histVC;
    }
    else if([itemName compare:@"实时观看"] == NSOrderedSame)
    {
#if 1
        if (_accountManager.currentAccount == _accountManager.guestAccount) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"请点击左上角图标登陆" message:@"游客身份无法通过其他跑友验证" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
        else _window.rootViewController = _realplayListVC;
#else
        _window.rootViewController = _workoutListVC;
#endif
    }
    else if([itemName compare:@"好友们"] == NSOrderedSame)
    {
        if (_accountManager.currentAccount == _accountManager.guestAccount) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"请点击左上角图标登陆" message:@"游客身份无法通过其他跑友验证" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
        else
        _window.rootViewController = _friendsVC;
    }
    else if([itemName compare:@"我的团"] == NSOrderedSame)
    {
        if (_accountManager.currentAccount == _accountManager.guestAccount) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"点击游客头像登陆吧！" message:@"游客身份无法通过其他跑友验证" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
        else
        _window.rootViewController = _friendGroup;
    }
    else if([itemName compare:@"设置"] == NSOrderedSame)
    {
        _window.rootViewController = _settingsVC;
    }

    [self hideMenu];
}

- (void) onRunFinished:(id)workout
{
    _window.rootViewController = _histVC;
    [_histVC presentWorkout:workout];
}

- (NSMutableAttributedString *) formatText:(NSString *)title subTitle:(NSString *)sub isHead:(BOOL)head
{
    UIColor *clrCapHead = [UIColor whiteColor];
    UIColor *clrCapNormal = [UIColor colorWithRed:0xc9/255.0 green:0xc9/255.0 blue:0xcb/255.0 alpha:1.0];
    UIColor *clrSub = [UIColor colorWithRed:0xab/255.0 green:0xab/255.0 blue:0xad/255.0 alpha:1.0];
    NSDictionary *attrDict1 = @{ NSFontAttributeName: [UIFont fontWithName:MAJORDATA_TITLE_FONT_NAME size:(head?MAJORDATA_TITLE_FONT_SIZE:MINORDATA_TITLE_FONT_SIZE)],
                                 NSForegroundColorAttributeName: (head?clrCapHead:clrCapNormal) };
    NSAttributedString *attrStr1 = [[NSAttributedString alloc] initWithString:title attributes: attrDict1];
    
    //第二段
    NSDictionary *attrDict2 = @{ NSFontAttributeName: [UIFont systemFontOfSize:MINORDATA_SUBTITLE_FONT_SIZE],
                                 NSForegroundColorAttributeName: clrSub };
    NSAttributedString *attrStr2 = [[NSAttributedString alloc] initWithString:sub attributes: attrDict2];
    
    //合并
    NSMutableAttributedString *attributedStr03 = [[NSMutableAttributedString alloc] initWithAttributedString: attrStr1];
    [attributedStr03 appendAttributedString: attrStr2];
    
    return attributedStr03;
}

- (XJStdWorkout *)getCurrentWorkout
{
    return _accountManager.currentAccount.workoutManager.currentWorkout;
}

- (void) createNewWorkout
{
    [_accountManager.currentAccount.workoutManager newCurrentWorkout];
}

#pragma  WX Delegate

/*该函数不用用户主动掉用*/
-(void) onReq:(BaseReq*)req
{
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
        /*
        NSString *strTitle = [NSString stringWithFormat:@"微信请求App提供内容"];
        NSString *strMsg = @"微信请求App提供内容，App要调用sendResp:GetMessageFromWXResp返回给微信";
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tag = 1000;
        [alert show];
        [alert release];*/
    }
    else if([req isKindOfClass:[ShowMessageFromWXReq class]])
    {
        //显示微信传过来的内容
        /*
        ShowMessageFromWXReq* temp = (ShowMessageFromWXReq*)req;
        WXMediaMessage *msg = temp.message;
        
        
        WXAppExtendObject *obj = msg.mediaObject;
        
        NSString *strTitle = [NSString stringWithFormat:@"微信请求App显示内容"];
        NSString *strMsg = [NSString stringWithFormat:@"标题：%@ \n内容：%@ \n附带信息：%@ \n缩略图:%u bytes\n\n", msg.title, msg.description, obj.extInfo, msg.thumbData.length];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
         [alert show];
         [alert release];*/
    }
    else if([req isKindOfClass:[LaunchFromWXReq class]])
    {
        //从微信启动App
        /*
        NSString *strTitle = [NSString stringWithFormat:@"从微信启动"];
        NSString *strMsg = @"这是从微信启动的消息";
         */
    }
    
}
/*该函数不用用户主动掉用*/
-(void) onResp:(BaseResp*)resp
{
    //send to timeline or session reponse, runhelper can alert some info here
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        /*
        NSString *strTitle = [NSString stringWithFormat:@"发送媒体消息结果"];
        NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
         */
    }
    
}
/*分享图片给好友/朋友圈/收藏
 WXSceneSession 好友,
 WXSceneTimeline 朋友圈,
 WXSceneFavorite  收藏,
 */
-(void)sendImageContent: (UIImage*)viewImage withScene:(int)scene
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = @"123go";
    message.description = @"让跑步称为一种习惯";
    message.mediaTagName = @"123go科技";
    [message setThumbImage:[UIImage imageNamed:@"maps.png"]];
    
    WXImageObject *ext = [WXImageObject object];
    ext.imageData = UIImagePNGRepresentation(viewImage);
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene =  scene;
    
    [WXApi sendReq:req];
    
    
    [WXApi sendReq:req];
    
}

/*分享文字给好友/朋友圈/收藏
 WXSceneSession 好友,
 WXSceneTimeline 朋友圈,
 WXSceneFavorite  收藏,
 */
- (void) sendTextContent: (NSString *)text withScene:(int)scene
{
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.text = text;//@"我的选择，叮叮跑步";
    req.bText = YES;
    req.scene = scene;
    
    [WXApi sendReq:req];
}


//---------------------------------------------------------------------------------------------
// Update heart rate
//---------------------------------------------------------------------------------------------
/*
 调用心率初始化函数后，如果检测到没有连接的心率设备，该函数会被调用，可以提示用户去设置里连接一个心率设备
 */
-(void)isheartRateAvailable: (BOOL)available;
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    XJStdWorkout *wo = [self getCurrentWorkout];
    if(wo != nil)
    {
        [wo appendHearRate:0 at:[NSDate date]];
    }

    if (available) {
        NSLog(@"HeartRateDevice available");
    }
    else
    {
        NSLog(@"HeartRateDevice not available");
        [app XJLog:@"BLE----------------------------"];
    }
}

-(void)didUpdateHeartRate:(unsigned short) heartRate
{
    NSString *stringInt = [NSString stringWithFormat:@"%d",heartRate];
    NSLog(@"Heart rate: %@", stringInt);
    XJStdWorkout *wo = [self getCurrentWorkout];
    if(wo != nil)
    {
        [wo appendHearRate:heartRate at:[NSDate date]];
    }
}

- (void) XJLog:(NSString *)string
{
    [_logger log:string];
}

- (void) simulateHeartRate:(BOOL)simu
{
    _heartRateDev.simulator = simu;
}

// how to map Markman distance to points
// original psd file is 960x??, designed for 5S
- (void) calcUIScale
{
    CGRect rcScreen = [[UIScreen mainScreen] bounds];
    float w = rcScreen.size.width;
    float h = rcScreen.size.height;
    NSLog(@"pixels: %d x %d", (int)w, (int)h);
    if(w > h)
        w = h;
    rate_pixel_to_point = w / 960.0;
}

@end

UIViewController * findViewController(UIView *sourceView)
{
#if 1
    id target=sourceView;
    while (target) {
        target = ((UIResponder *)target).nextResponder;
        if ([target isKindOfClass:[UIViewController class]]) {
            break;
        }
    }
    return target;
#else
    //nav为root UINavigationController
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    UIViewController *viewController = delegate.nav.visibleViewController;
    return viewController;
#endif
}

NSString * stringFromDate(NSDate *date)
{
    static NSDateFormatter *dateFormatter = nil;
    if(dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
    
        // zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息。
        // [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
    }

    NSString *destDateString = [dateFormatter stringFromDate:date];
    return destDateString;
}

NSDate * getDateFromDictionary(NSDictionary *dict, NSString *key)
{
    NSString *val;

    val = [dict objectForKey:key];
    if((NSNull *)val != [NSNull null])
        return getDateFromString(val);
    else
        return nil;
}

NSDate * getDateFromString(NSString *string)
{
    static NSDateFormatter *dateFormatter = nil;
    if(dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];

        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
    }

    NSDate *tm = [dateFormatter dateFromString:string];
    return tm;
}

NSMutableAttributedString * formatText(NSString *title, NSString *sub, BOOL head)
{
    NSDictionary *attrDict1 = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:(head?96:20)],
                                 NSForegroundColorAttributeName: [UIColor blackColor] };
    NSAttributedString *attrStr1 = [[NSAttributedString alloc] initWithString:title attributes: attrDict1];
    
    //第二段
    NSDictionary *attrDict2 = @{ NSFontAttributeName: [UIFont systemFontOfSize:10],
                                 NSForegroundColorAttributeName: [UIColor grayColor] };
    NSAttributedString *attrStr2 = [[NSAttributedString alloc] initWithString:sub attributes: attrDict2];
    
    //合并
    NSMutableAttributedString *attributedStr03 = [[NSMutableAttributedString alloc] initWithAttributedString: attrStr1];
    [attributedStr03 appendAttributedString: attrStr2];
    
    return attributedStr03;
}

#import <AVFoundation/AVFoundation.h>
void say(NSString *sth)
{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if(app.accountManager.currentAccount.voiceHelper == YES)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];

        NSError *setCategoryError = nil;
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];

        NSError *activationError = nil;
        [audioSession setActive:YES error:&activationError];

        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:sth];
        utterance.rate = 0.3f;
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:[AVSpeechSynthesisVoice currentLanguageCode]];
//        utterance.rate *= 0.5;
//        utterance.pitchMultiplier = 0.5;

        AVSpeechSynthesizer *synth = [[AVSpeechSynthesizer alloc] init];
        [synth speakUtterance:utterance];
    }
}

NSString *gpsLevel(double acc)
{
    /*if(acc > 500)
    {
        return @"极弱";
    }
    else if(acc > 50)
    {
        return @"微弱";
    }
    else */if(acc > 20)
    {
        return @"弱";
    }
/*    else if(acc > 10)
    {
        return @"好";
    }
    else if(acc > 5)
    {
        return @"良";
    }*/
    else if(acc >= 0)
    {
        return @"强";
    }
    else
    {
        return @"无";
    }
}

// cannot be too long!
int myprintf(const char *fmt, ...)
{
    char buf[1024 * 8];
    buf[0] = 0;
    va_list args;
    va_start(args, fmt);
    int n = vsprintf(buf, fmt, args);
    va_end(args);
    NSString *string = [[NSString alloc] initWithCString:buf encoding:(NSASCIIStringEncoding)];

    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [app XJLog:string];
    
    return n;
}
