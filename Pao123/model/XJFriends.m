//
//  XJFriends.m
//  Pao123
//
//  Created by 张志阳 on 15/6/29.
//  Copyright (c) 2015年 XingJian Software. All rights reserved.
//

#import "XJFriends.h"
@interface XJFriends()
{

}
@end
@implementation XJFriends
-(instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(instancetype)initWithId:(NSInteger)myId name:(NSString *)name nickName:(NSString *) nickName
{
    self = [super init];
    if (self) {
        _myId = myId;
        _name = name;
        _nickName = nickName;
    }
    return self;
}
@end
