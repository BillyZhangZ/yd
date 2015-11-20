//
//  XJAccount.m
//  Pao123
//
//  Created by Zhenyong Chen on 6/23/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#import "config.h"
#import "XJAccount.h"
#import "XJFriends.h"
#import "XJRunGroup.h"
@interface XJAccount ()
{
    BOOL _isGuest;
    char _layout[5];
}

@end

@implementation XJAccount

- (instancetype) init:(BOOL)isGuest name:(NSString *)userName userID:(NSUInteger)userID
{
    self = [super init];

    if(self != nil)
    {
        _userID = userID;
        _user = userName;
        _friends = [[NSMutableArray alloc] init];
        _runGroups = [[NSMutableArray alloc] init];
        _autoPause = NO;
        _sex = 0;
        _isGuest = isGuest;
        _height = 170;
        _weight = 70;
        _voiceHelper = YES;
        strcpy(_layout, "hpdl"); // heart rate, pace, duration, length
        _btnLayout = _layout;
        [self loadPreference];
        _workoutManager = [[XJWorkoutManager alloc] init:self];
    }

    return self;
}

- (void) login:(void (^)(BOOL ok))cb
{
    if(!_isGuest)
    {
        [self verifyWechatAccount:cb];
    }
    else
    {
        if(cb != nil)
            cb(YES);
    }
}

- (void) logout
{
    // do nothing
}

- (void) verifyWechatAccount:(void (^)(BOOL ok))cb
{
    void(^cblock)(NSString *) = ^(NSString *name){
        // use wechat name to override _user
        if([name compare:@"测试2"] == NSOrderedSame)
            name = nil; // simulate the failure
        self.user = name;

        // get user ID or return failure
        if(self.user != nil) {
            [self obtainUserID:cb];
        }
        else {
            if(cb != nil) {
                cb(NO);
            }
        }

    };

    // send request and pass cblock to it; here call cblock
    cblock(_user);
}

- (void) obtainUserID:(void (^)(BOOL ok))cb
{
    NSString *urlString = URL_GET_USER_INFO;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    NSString *string = [NSString stringWithFormat:@"username=%@", self.user];
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                if(error == nil && data != nil) {
                                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                    NSString *sID = [dict objectForKey:@"id"];
                                    NSString *sName = [dict objectForKey:@"name"];
                                    _userID = [sID intValue];
                                    
                                    NSAssert([sName compare:self.user] == NSOrderedSame, @"Bad user name returned");

                                    [self loadPreference];

                                    if(cb != nil)
                                        cb(YES);
                               }
                                else {
                                    if(cb != nil)
                                        cb(NO);
                                }
                           }];
}

- (void) addFriend:(NSInteger)friendId complete:(void(^)(bool))cb
{
    //search whether this gay is my friend
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_APPLY_TO_ADD_FRIEND];
    [urlPost appendFormat:@"%lu",(unsigned long)_userID];
    
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    NSString *body = [[NSString alloc] initWithFormat:@"friendid=%ld&userid=%ld",(long)friendId,(unsigned long)_userID];
    NSLog(@"正在添加好友%ld", (long)friendId);
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            NSLog(@"add friend failed");
            cb(false);
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSInteger returnValue =[[dict valueForKey:@"id"] integerValue];
        if (returnValue != 0) {
            NSLog(@"添加好友成功");
            cb(true);
        }
        else
        {
            cb(false);
            NSLog(@"添加好友失败");
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

    return;
}

- (BOOL) rmFriend:(NSInteger)userId;
{
    NSUInteger count = [_friends count];
    if (count == 0)  return false;
    
    for (XJFriends *friendItem in _friends) {
        if (friendItem.myId == userId) {
            [_friends removeObject:friendItem];
            return true;
        }
    }
    return false;
}

- (XJFriends *) findFriend:(NSInteger)userId
{
    
    NSUInteger count = [_friends count];
    if (count == 0)  return nil;
    
    for (XJFriends *friendItem in _friends) {
        if (friendItem.myId == userId) {
            return friendItem;
        }
    }
    
    return nil;
}

-(void)getApplyFriendList:(void (^)(BOOL ok))cb
{
    NSString *urlString = [NSString stringWithFormat:URL_GET_APPLY_FRIEND_LIST@"/%lu", (unsigned long)self.userID];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    //[request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
                                {
                               if(error == nil && data != nil) {
                                   NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                   if (dict == nil) {
                                       return ;
                                   }
                                   if ([[dict valueForKey:@"id"]integerValue] != 0) {
                                       NSDictionary *friendList = [dict valueForKey:@"apply"];
                                       for (NSString *friendItem in friendList) {
                                           NSInteger friendId = [[friendItem valueForKey:@"userid"] integerValue];
                                           
                                           if ([self findFriend:friendId]) {
                                               continue;
                                           }
                                           NSString *nickName = @"我没昵称";
                                           if ((NSNull *)[friendItem valueForKey:@"nickname"] != [NSNull null]) {
                                               nickName = [friendItem valueForKey:@"nickname"];
                                           }
                                           
                                           XJFriends *friend = [[XJFriends alloc]initWithId:[[friendItem valueForKey:@"userid"] integerValue ]name:[friendItem valueForKey:@"username"] nickName:nickName];
                                           friend.pendingState = STATE_WAIT_FOR_APPROVE;
                                          
                                           [self.friends addObject:friend];
                                       }
                                       NSLog(@"%lu个好友申请中", (unsigned long)[self.friends count]);
                                       cb(YES);
                                   }
                                   else
                                   {
                                       NSLog(@"无好友申请");
                                       cb(NO);
                                   }
                               }
                                    else cb(NO);}
                               ];

}

-(void)getFriendList:(void (^)(BOOL ok))cb
{
    NSString *urlString = [NSString stringWithFormat:URL_GET_FRIEND_LIST@"/%lu", (unsigned long)self.userID];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    //[request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:10.0f];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if(error == nil && data != nil) {
             NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
             if (dict == nil) {
                 return ;
             }
             if ([[dict valueForKey:@"id"]integerValue] != 0) {
                 [_friends removeAllObjects];
                 NSDictionary *friendList = [dict valueForKey:@"friends"];
                 for (NSString *friendItem in friendList) {
                     NSInteger friendId = [[friendItem valueForKey:@"id"] integerValue];
                     
                     if ([self findFriend:friendId]) {
                         continue;
                     }
                     NSString *nickName = @"我没昵称";
                     if ((NSNull *)[friendItem valueForKey:@"nickname"] != [NSNull null]) {
                         nickName = [friendItem valueForKey:@"nickname"];
                     }
                     
                     XJFriends *friend = [[XJFriends alloc]initWithId:friendId name:[friendItem valueForKey:@"name"] nickName:nickName];
                     friend.pendingState = STATE_ALREADY_FRIEND;
                     
                     [self.friends addObject:friend];
                 }
                 NSLog(@"获取%lu个好友", (unsigned long)[self.friends count]);
                 cb(YES);
             }
             else
             {
                 NSLog(@"获取0个好友");
                 cb(NO);
             }
         }
         else cb(NO);}
     ];
    
}


-(void)getFriendGroupFromServer:(void(^)(bool))cb
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_GET_USER_RUN_GROUP_INFO];
    [urlPost appendFormat:@"%lu",(unsigned long)_userID];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            cb(false);
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            [self proccessResponse:dict];
            cb(true);
            return;
        }
        else
        {
            cb(false);
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
    NSDictionary *ownedGroup = [dict valueForKey:@"owngroup"];
    NSDictionary *joinedGroup = [dict valueForKey:@"joingroup"];
    NSDictionary *appliedGroup = [dict valueForKey:@"applygroup"];
    [_runGroups removeAllObjects];
    
    for (NSDictionary *groupItem in ownedGroup) {
        XJRunGroup *group = [[XJRunGroup alloc]init];
        group.groupId = [[groupItem valueForKey:@"id"] integerValue];
        group.groupName = [groupItem valueForKey:@"name"];
        group.signature = [groupItem valueForKey:@"description"];
        group.memberCount = [[groupItem valueForKey:@"membercount"] integerValue];
        group.activeMemberCount = [[groupItem valueForKey:@"memberrunningcount"] integerValue];
        group.relationship = RELATIONSHIP_OWN;
        group.applyMemberCount = [[groupItem valueForKey:@"memberapplycount"] integerValue];
        [_runGroups addObject:group];
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
        [_runGroups addObject:group];
    }
    for (NSDictionary *groupItem in appliedGroup) {
        XJRunGroup *group = [[XJRunGroup alloc]init];
        group.groupId = [[groupItem valueForKey:@"id"] integerValue];
        group.groupName = [groupItem valueForKey:@"name"];
        group.signature = [groupItem valueForKey:@"description"];
        group.memberCount = [[groupItem valueForKey:@"membercount"] integerValue];
        group.activeMemberCount = [[groupItem valueForKey:@"memberrunningcount"] integerValue];
        group.relationship = RELATIONSHIP_APPLY;
        group.applyMemberCount = [[groupItem valueForKey:@"memberapplycount"] integerValue];
        [_runGroups addObject:group];
    }
}

+ (NSString *) getUUID
{
    return [[NSUUID UUID] UUIDString];
}

- (void) setAutoPause:(BOOL)autoPause
{
    _autoPause = autoPause;
    [self storePreference];
}

- (void) setBtnLayout:(char *)btnLayout
{
    memcpy(_btnLayout, btnLayout, 4);
    [self storePreference];
}

- (void) setVoiceHelper:(BOOL)voiceHelper
{
    _voiceHelper = voiceHelper;
    [self storePreference];
}

- (BOOL) loadPreference
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *user = [NSString stringWithFormat:@"%d.plist", (int)self.userID];
    NSString *prefFile = [path stringByAppendingPathComponent:user];

    // load data
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:prefFile];
    if(dict == nil)
        return NO;

    id val;
    val = [dict valueForKey:@"autoPause"];
    if(val != 0) {
        NSString *sVal = val;
        _autoPause = [sVal boolValue]; // do not use self.autoPause to prevent storePreference to be called
    }

    val = [dict valueForKey:@"dataLayout"];
    if(val != 0) {
        NSString *sVal = val;
        if(sVal.length == 4) {
            for(NSUInteger i=0; i<4; i++) {
                unichar c = [sVal characterAtIndex:i];
                _btnLayout[i] = c;
            }
        }
    }

    val = [dict valueForKey:@"voiceHelper"];
    if(val != 0) {
        NSString *sVal = val;
        _voiceHelper = [sVal boolValue];
    }

    return YES;
}

- (BOOL) storePreference
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *user = [NSString stringWithFormat:@"%d.plist", (int)self.userID];
    NSString *prefFile = [path stringByAppendingPathComponent:user];

    // store data
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSString *sVal;
    if(self.autoPause == YES)
        sVal = @"1";
    else
        sVal = @"0";
    [dict setValue:sVal forKey:@"autoPause"];
    sVal = [NSString stringWithCString:_btnLayout encoding:NSASCIIStringEncoding];

    [dict setValue:sVal forKey:@"dataLayout"];

    if(self.voiceHelper == YES)
        sVal = @"1";
    else
        sVal = @"0";
    [dict setValue:sVal forKey:@"voiceHelper"];

    BOOL ok = [dict writeToFile:prefFile atomically:YES];
    return ok;
}

@end
