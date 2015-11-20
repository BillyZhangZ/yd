//
//  XJRunGroup.m
//  Pao123
//
//  Created by 张志阳 on 15/7/4.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJRunGroup.h"
#import "config.h"
#import "XJFriends.h"
@interface XJRunGroup()
{

}
@end

@implementation XJRunGroup
-(instancetype)init
{
    self =  [super init];
    if (self) {
        _groupId = 0;
        _groupName = nil;
        _signature = nil;
        _relationship = 0;
        _memberCount = 0;
        _activeMemberCount = 0;
        _applyMemberCount = 0;
        _allMembers = [[NSMutableArray alloc]init];
        _activeMembers = [[NSMutableArray alloc]init];
    }
    return  self;
}

-(void)getActiveGroupMembers:(void (^)(bool))cb
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_GET_RUN_GROUP_MEMBERS];
    [urlPost appendFormat:@"%lu",(unsigned long)_groupId];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    NSLog(@"get active member");
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            cb(false);
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            [self proccessFetchMemberResponse:dict];
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

-(void)proccessFetchMemberResponse:(NSDictionary *)dict
{
    NSDictionary *userList = [dict valueForKey:@"member"];
    
    for (NSDictionary *user in userList) {
        XJFriends *friend = [[XJFriends alloc]init];
        if ([[user objectForKey:@"isrunning"]integerValue] == 0) {
            continue;
        }
        friend.myId = [[user objectForKey:@"id"] integerValue];
        friend.name = [user objectForKey:@"name"];
        if ((NSNull *)[user objectForKey:@"nickname"] != [NSNull null]) {
            friend.nickName = [user objectForKey:@"nickname"];
        }
        else
        {
            friend.nickName = @"我没昵称";
        }
        [_activeMembers addObject:friend];
    }
}

-(void)getGroupInfo:(void (^)(bool))cb
{
    NSMutableString *urlPost = [[NSMutableString alloc] initWithString:URL_GET_RUN_GROUP_INFO];
    [urlPost appendFormat:@"%lu",(unsigned long)_groupId];
    NSURL *url = [NSURL URLWithString:urlPost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10.0f];
    NSLog(@"get active member");
    void (^onDone)(NSData *data) = ^(NSData *data) {
        if(data == nil)
        {
            cb(false);
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        if ([[dict valueForKey:@"id"]integerValue] != 0) {
            //return id/name/description
            NSDictionary *group = [dict valueForKey:@"rungroup"];
            _signature = [group valueForKey:@"description"];
            _groupName = [group valueForKey:@"name"];
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
@end
