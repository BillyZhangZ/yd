//
//  XJAccountManager.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/15/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJAccountManager.h"
#import "XJAccount.h"
#import "XJRunGroup.h"
#import "XJFriends.h"
#import "AppDelegate.h"
@interface XJAccountManager ()
{
    XJAccount *_guestAccount; // guest account: always exists
    XJAccount *_anotherAccount; // verified user account
    XJAccount *_currentAccount; // point to _guestAccount or _anotherAccount
}
@end

@implementation XJAccountManager

- (instancetype) init
{
    self = [super init];

    if(self != nil)
    {
        // use guest account automatically
        NSString *guestName = [NSString stringWithFormat:@"游客"];
        _guestAccount = [[XJAccount alloc] init:YES name:guestName userID:USERID];
        _currentAccount = _guestAccount;

        NSDictionary *accountInfo = [self loadCurrentAccountInfo];
        if (accountInfo == nil) {
            return self;
        }
        NSString *accountName = [accountInfo valueForKey:@"name"];
        NSString *accountId = [accountInfo valueForKey:@"id"];
        if ([accountName isEqual: @""] || [accountId isEqual: @""]) {
            //guest
        } else{
            //正式用户
            _anotherAccount = [[XJAccount alloc] init:NO name:accountName userID:[accountId integerValue]];
            _currentAccount = _anotherAccount;
        }
        [self loadAccountInfoFromDisk];
        [_currentAccount.workoutManager loadWorkoutsFromLocalDataFile];
    }
    return self;
}

-(NSDictionary *)loadCurrentAccountInfo
{
    //获取应用程序沙盒的Documents目录
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *plistPath1 = [paths objectAtIndex:0];
    
    //得到完整的文件名
    NSString *filename=[plistPath1 stringByAppendingPathComponent:@"Account.plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:filename];
    return data;
}

-(BOOL)storeCurrentAccountInfo:(NSString *)accountName userId:(NSString *)userId
{
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path=[paths objectAtIndex:0];
   // NSLog(@"path = %@",path);
    NSString *plistPath=[path stringByAppendingPathComponent:@"Account.plist"];
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:plistPath]) {
        [fm createFileAtPath: plistPath contents:nil attributes:nil];
        NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"id",@"0",@"name",nil];
        [dic writeToFile:plistPath atomically:YES];
    }

    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [data setObject:accountName forKey:@"name"];
    [data setObject:userId forKey:@"id"];
    
    //得到完整的文件名
    NSString *filename=[path stringByAppendingPathComponent:@"Account.plist"];
    //输入写入
    [data writeToFile:filename atomically:YES];
    
    //NSMutableDictionary *data1 = [[NSMutableDictionary alloc] initWithContentsOfFile:filename];
    //NSLog(@"%@", data1);
    

    return true;
}

-(void)registerWithMobilePhone:(NSString *)phoneNumber complete:(void (^)(bool ok, NSInteger userId))cb
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_USER_REGISTER];
    
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    NSString *string;
    if (app.devicePushId == nil) {
        string = [[NSString alloc] initWithFormat:@"name=%@&deviceos=%d",phoneNumber, IOS_DEVICE];
    }
    else
    {
        string = [[NSString alloc] initWithFormat:@"name=%@&devicepushid=%@&deviceos=%d",phoneNumber,app.devicePushId, IOS_DEVICE];
    }
    NSLog(@"%@",string);
    
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            NSLog(@"Register: remote server return nil");
            cb(false, 0);
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSInteger userId = [[dict valueForKey:@"id"] integerValue];
        if (userId == 0) {
            NSLog(@"用户已经注册");
            cb(false, 0);
            return;
        }
        else
        {
            cb(true, userId);
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
-(void)loginWithMobilePhone:(NSString *)phoneNumber complete:(void (^)(bool))cb
{
    //验证成功，根据是否为新用户跳转
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_USER_LOGIN];
    
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    
    NSString *string;
    AppDelegate *app = [[UIApplication sharedApplication]delegate];
    if (app.devicePushId == nil) {
        string = [[NSString alloc] initWithFormat:@"name=%@&deviceos=%d",phoneNumber, IOS_DEVICE];
    }
    else
    {
        string = [[NSString alloc] initWithFormat:@"name=%@&devicepushid=%@&deviceos=%d",phoneNumber,app.devicePushId, IOS_DEVICE];
    }
    NSLog(@"%@",string);
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:15.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            NSLog(@"Login: remote server return nil");
            cb(false);
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSInteger userId = [[dict valueForKey:@"id"] integerValue];
        NSString *name = [dict valueForKey:@"name"];
        
        if ((NSNull *)name == [NSNull null]) {
            name = @"";
        }
        if ([self logIn:name userId:userId]) {
            [self updateAccountInfo: dict];
            cb(true);
        }
        else
        {
            cb(false);
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

- (BOOL) logIn:(NSString *)userName userId:(NSInteger)userId
{
    if (userName == nil || userId == 0)
        return false;
    XJAccount *tmpAccount = [[XJAccount alloc] init:NO name:userName userID:userId];
    _anotherAccount = [[XJAccount alloc] init:NO name:tmpAccount.user userID:tmpAccount.userID];
    [self setValue:_anotherAccount forKey:@"currentAccount"];
    [self storeCurrentAccountInfo:tmpAccount.user userId:[NSString stringWithFormat:@"%lu",(unsigned long)tmpAccount.userID]];
    [_currentAccount.workoutManager loadWorkoutsFromLocalDataFile];
    [self loadAccountInfoFromDisk];

    return true;
}

- (void) logIn:(BOOL)asGuest name:(NSString *)userName complete:(void (^)(BOOL))cb
{
    if(asGuest)
    {
        if(self.currentAccount != _guestAccount)
        {
            // user -> guest
            NSAssert(_currentAccount == _anotherAccount, @"Bad current account");
            [self setValue:_guestAccount forKey:@"currentAccount"];
            _anotherAccount = nil;
        }
        else
        {
            // guest -> guest: do nothing
        }
        [self storeCurrentAccountInfo:@"" userId:@""];
        [_currentAccount.workoutManager loadWorkoutsFromLocalDataFile];
        [self loadAccountInfoFromDisk];

        if(cb != NULL)
            cb(YES);
    }
    else
    {
        if(self.currentAccount == _guestAccount || [self.currentAccount.user compare:userName] != NSOrderedSame)
        {
            // guest -> user or userA -> userB
            XJAccount *tmpAccount = [[XJAccount alloc] init:NO name:userName userID:0];
            void (^intCb)(BOOL ok) = ^(BOOL ok) {
                if(ok)
                {
                    NSAssert(tmpAccount.user != nil, @"empty user name");
                    NSAssert(tmpAccount.userID != 0, @"zero user ID");
                    _anotherAccount = [[XJAccount alloc] init:NO name:tmpAccount.user userID:tmpAccount.userID];
                    // notify that account changed
                    [self setValue:_anotherAccount forKey:@"currentAccount"];
                    [self storeCurrentAccountInfo:tmpAccount.user userId:[NSString stringWithFormat:@"%lu",(unsigned long)tmpAccount.userID]];
                }

                // account changed, call back
                if(cb != NULL)
                    cb(ok);
            };
            [tmpAccount login:intCb];
        }
        else
        {
            // userA -> userA: do nothing
            if(cb != NULL)
                cb(YES);
        }
    }
}


-(void)updateAccountInfo:(NSDictionary *)accountInfo
{
    [self updateRamAccountInfo:accountInfo];
    [self storeAccountInfoToDisk];
}

//update RAM account infomation
- (BOOL) updateRamAccountInfo:(NSDictionary *)accountInfo
{
    id var;
    if (accountInfo == nil) {
        return false;
    }

    NSString *userId = [accountInfo valueForKey:@"id"];
    NSString *name = [accountInfo valueForKey:@"name"];
    NSString *nickName = @"我没昵称";
    if ([NSNull null] != (NSNull *)[accountInfo valueForKey:@"nickname"]) {
        nickName = [accountInfo valueForKey:@"nickname"];
    }

    if ((NSNull *)userId == [NSNull null] || (NSNull *)name == [NSNull null] || (NSNull *)nickName == [NSNull null]) {
        return false;
    }
    NSInteger age, weight, height, sex;
    if([NSNull null] != [accountInfo valueForKey:@"age"])
    {
        age = [[accountInfo valueForKey:@"age"] integerValue];
    }
    else age = 0;
    if([NSNull null] != [accountInfo valueForKey:@"sex"])
    {
        sex = [[accountInfo valueForKey:@"sex"] integerValue];
        if (sex == 0) {
            sex = MALE;
        }
    }
    else sex = MALE;
    if([NSNull null] != [accountInfo valueForKey:@"weight"])
    {
        weight = [[accountInfo valueForKey:@"weight"] integerValue];
    }
    else weight = 70;
    if([NSNull null] != [accountInfo valueForKey:@"height"])
    {
        height = [[accountInfo valueForKey:@"height"] integerValue];
    }
    else height = 170;
    
    var = [accountInfo valueForKey:@"registerdate"];
    if ((NSNull *)var == [NSNull null]) {
        return false;
    }
    NSDate *registerdate = getDateFromString((NSString *)var);
    
    _currentAccount.userID = [userId integerValue];
    _currentAccount.user = name;
    _currentAccount.nickName = nickName;
    _currentAccount.age = age;
    _currentAccount.sex = sex;
    _currentAccount.weight = weight;
    _currentAccount.height = height;
    _currentAccount.registerdate = registerdate;
    
    [_currentAccount.friends removeAllObjects];
    [_currentAccount.runGroups removeAllObjects];
    NSDictionary *friendDict = [accountInfo valueForKey:@"friends"];
#pragma mark not sure this judgement here
    if ((NSNull *)friendDict != [NSNull null]) {
        [_currentAccount.friends removeAllObjects];
        for (NSDictionary* friendItemDict in friendDict) {
            XJFriends *f = [[XJFriends alloc]init];
            f.myId = [[friendItemDict valueForKey:@"id"] integerValue];
            f.name = [friendItemDict valueForKey:@"name"];
            f.nickName = [friendItemDict valueForKey:@"nickname"];
            if ((NSNull *)f.nickName == [NSNull null]) {
                f.nickName = @"我没昵称";
            }
            f.pendingState = STATE_ALREADY_FRIEND;
            [_currentAccount.friends addObject:f];
        }
    }
    
    NSDictionary *groupDict = [accountInfo valueForKey:@"groups"];
    if ((NSNull *)groupDict != [NSNull null]) {
        [_currentAccount.runGroups removeAllObjects];
        for (NSDictionary* groupItemDict in groupDict) {
            XJRunGroup *group = [[XJRunGroup alloc]init];
            group.groupId = [[groupItemDict valueForKey:@"id"] integerValue];
            group.groupName = [groupItemDict valueForKey:@"name"];
            group.signature = [groupItemDict valueForKey:@"description"];
            group.relationship = [[groupItemDict valueForKey:@"relationship"] integerValue];
            group.memberCount = [[groupItemDict valueForKey:@"membercount"] integerValue];
            [_currentAccount.runGroups addObject:group];
        }
    }
    return true;
}

//update disk account infomation
-(BOOL)storeAccountInfoToDisk
{
    //load infomation to a dictionary for write to plist file
    NSMutableDictionary *accountInfoDict = [[NSMutableDictionary alloc]init];
    NSMutableArray *friendsInfoArray = [[NSMutableArray alloc]init];
    NSMutableArray *groupsInfoArray = [[NSMutableArray alloc]init];

    [accountInfoDict setObject:[NSString stringWithFormat:@"%ld", (unsigned long)_currentAccount.userID] forKey:@"id"];
    [accountInfoDict setObject:_currentAccount.user forKey:@"name"];
    if (_currentAccount.nickName == nil) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"无昵称" message:@"" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return false;
    }
    [accountInfoDict setObject:_currentAccount.nickName forKey:@"nickname"];
    [accountInfoDict setObject:[NSString stringWithFormat:@"%ld", (unsigned long)_currentAccount.age]  forKey:@"age"];
    [accountInfoDict setObject:[NSString stringWithFormat:@"%ld", (unsigned long)_currentAccount.sex]  forKey:@"sex"];
    [accountInfoDict setObject:[NSString stringWithFormat:@"%ld", (unsigned long)_currentAccount.weight]  forKey:@"weight"];
    [accountInfoDict setObject:[NSString stringWithFormat:@"%ld", (unsigned long)_currentAccount.height]  forKey:@"height"];
    [accountInfoDict setObject:stringFromDate(_currentAccount.registerdate)  forKey:@"registerdate"];
    [accountInfoDict setObject:friendsInfoArray forKey:@"friends"];
    [accountInfoDict setObject:groupsInfoArray forKey:@"groups"];

    for (XJFriends *f in _currentAccount.friends) {
        NSMutableDictionary *friendItem = [[NSMutableDictionary alloc] init];
        [friendItem setObject:[NSString stringWithFormat:@"%ld",(unsigned long)f.myId] forKey:@"id"];
        [friendItem setObject:f.name forKey:@"name"];
        [friendItem setObject:f.nickName forKey:@"nickname"];
        [friendsInfoArray addObject:friendItem];
    }
    
    for (XJRunGroup *group in _currentAccount.runGroups) {
        NSMutableDictionary *groupItem = [[NSMutableDictionary alloc] init];
        [groupItem setObject:[NSString stringWithFormat:@"%ld",(long)group.groupId] forKey:@"id"];
        [groupItem setObject:group.groupName forKey:@"name"];
        [groupItem setObject:group.signature forKey:@"description"];
        [groupItem setObject:[NSString stringWithFormat:@"%ld",(long)group.relationship] forKey:@"relationship"];
        [groupItem setObject:[NSString stringWithFormat:@"%ld",(long)group.memberCount] forKey:@"membercount"];

        [groupsInfoArray addObject:groupItem];
    }

    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path=[paths objectAtIndex:0];
    NSString *plistDir=[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld/", (unsigned long)_currentAccount.userID]];
    NSString *plistPath=[plistDir stringByAppendingPathComponent:@"info.plist"];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    //判断文件夹是否存在并创建
    BOOL isDir = FALSE;
    BOOL isDirExist = [fm fileExistsAtPath:plistDir isDirectory:&isDir];
    BOOL ret = false;
    if(!(isDirExist && isDir))
    {
        ret = [fm createDirectoryAtPath:plistDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        if(!ret){
            NSLog(@"Create Account Directory Failed.");
            return false;
        }
    }
    //判断文件是否存在并创建
    if (![fm fileExistsAtPath:plistPath]) {
        
        ret = [fm createFileAtPath: plistPath contents:nil attributes:nil];
        if (!ret) {
            return false;
        }
    }

    [accountInfoDict writeToFile:plistPath atomically:YES];

    //NSMutableDictionary *data1 = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    //NSLog(@"%@", data1);
    return true;
}

//load disk account infomation
-(BOOL)loadAccountInfoFromDisk
{
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path=[paths objectAtIndex:0];
    NSString *plistPath=[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld/info.plist",(unsigned long)_currentAccount.userID]];
    BOOL ret = false;
    //判断文件是否存在，不存在则返回
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:plistPath]) {
        return false;
    }
    
    NSMutableDictionary *accountInfoDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    
    ret = [self updateRamAccountInfo:accountInfoDict];
    if (!ret) {
        return false;
    }
    
    return true;
}


-(void)uploadAccountInfo:(void (^)(bool))cb
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_UPDATE_USER_INFO];
    [urlPost appendFormat:@"%lu",(unsigned long)_currentAccount.userID];

    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    NSString *string = [[NSString alloc] initWithFormat:@"weight=%ld&height=%ld&gender=%ld&age=%ld",(long)_currentAccount.weight, (long)_currentAccount.height, (long)_currentAccount.sex,(long)_currentAccount.age];
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            NSLog(@"无网路，无法删除");
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSInteger userId =[[dict valueForKey:@"id"] integerValue];
        if (userId != 0) {
            NSLog(@"update ok");
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"删除失败" message:@"服务器拒绝" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
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
